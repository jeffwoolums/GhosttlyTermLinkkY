/**
 * Terminal Session Manager
 * 
 * Handles PTY creation and management for remote terminal access
 */

import pty from 'node-pty';
import { v4 as uuidv4 } from 'uuid';
import { config } from '../config.js';
import { logger } from '../utils/logger.js';

export class TerminalManager {
  constructor() {
    this.sessions = new Map();
  }
  
  /**
   * Create a new terminal session
   */
  createSession(ws, options = {}) {
    if (this.sessions.size >= config.maxSessions) {
      throw new Error('Maximum session limit reached');
    }
    
    const sessionId = uuidv4();
    const shell = options.shell || config.shell;
    const cwd = options.cwd || config.defaultCwd;
    
    logger.info(`Creating session ${sessionId} with shell: ${shell}, cwd: ${cwd}`);
    
    // Spawn PTY process
    const ptyProcess = pty.spawn(shell, [], {
      name: 'xterm-256color',
      cols: options.cols || 80,
      rows: options.rows || 24,
      cwd: cwd,
      env: {
        ...process.env,
        ...options.env,
        TERM: 'xterm-256color',
        COLORTERM: 'truecolor',
        GHOSTTLY_SESSION: sessionId,
      }
    });
    
    // Handle PTY output -> send to WebSocket
    ptyProcess.onData((data) => {
      if (ws.readyState === ws.OPEN) {
        ws.send(JSON.stringify({
          type: 'output',
          data: data
        }));
      }
    });
    
    // Handle PTY exit
    ptyProcess.onExit(({ exitCode, signal }) => {
      logger.info(`Session ${sessionId} PTY exited: code=${exitCode}, signal=${signal}`);
      
      if (ws.readyState === ws.OPEN) {
        ws.send(JSON.stringify({
          type: 'exit',
          exitCode,
          signal
        }));
      }
      
      this.sessions.delete(sessionId);
    });
    
    // Store session
    this.sessions.set(sessionId, {
      id: sessionId,
      ws,
      pty: ptyProcess,
      clientIP: options.clientIP,
      createdAt: new Date(),
      lastActivity: new Date()
    });
    
    return sessionId;
  }
  
  /**
   * Write data to terminal
   */
  write(sessionId, data) {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.pty.write(data);
      session.lastActivity = new Date();
    }
  }
  
  /**
   * Resize terminal
   */
  resize(sessionId, cols, rows) {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.pty.resize(cols, rows);
      logger.debug(`Session ${sessionId} resized to ${cols}x${rows}`);
    }
  }
  
  /**
   * Destroy a session
   */
  destroySession(sessionId) {
    const session = this.sessions.get(sessionId);
    if (session) {
      try {
        session.pty.kill();
      } catch (e) {
        // PTY may already be dead
      }
      this.sessions.delete(sessionId);
      logger.info(`Session ${sessionId} destroyed`);
    }
  }
  
  /**
   * Destroy all sessions
   */
  destroyAll() {
    for (const sessionId of this.sessions.keys()) {
      this.destroySession(sessionId);
    }
  }
  
  /**
   * Get session count
   */
  getSessionCount() {
    return this.sessions.size;
  }
  
  /**
   * Get session info
   */
  getSessionInfo(sessionId) {
    const session = this.sessions.get(sessionId);
    if (!session) return null;
    
    return {
      id: session.id,
      clientIP: session.clientIP,
      createdAt: session.createdAt,
      lastActivity: session.lastActivity
    };
  }
}
