/**
 * Terminal Session Manager
 * 
 * Handles PTY creation and management for remote terminal access
 * Uses node-pty when available, falls back to child_process
 */

import { spawn } from 'child_process';
import { v4 as uuidv4 } from 'uuid';
import { config } from '../config.js';
import { logger } from '../utils/logger.js';

let pty = null;
let usePty = false;

// Try to load node-pty, fall back to child_process if it fails
try {
  const ptyModule = await import('node-pty');
  pty = ptyModule.default;
  usePty = true;
  logger.info('Using node-pty for terminal sessions');
} catch (e) {
  logger.warn(`node-pty not available, using child_process fallback: ${e.message}`);
}

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
    
    const env = {
      ...process.env,
      ...options.env,
      TERM: 'xterm-256color',
      COLORTERM: 'truecolor',
      GHOSTTLY_SESSION: sessionId,
    };
    
    let termProcess;
    
    if (usePty) {
      // Use node-pty for full PTY support
      try {
        termProcess = pty.spawn(shell, [], {
          name: 'xterm-256color',
          cols: options.cols || 80,
          rows: options.rows || 24,
          cwd: cwd,
          env: env
        });
        
        termProcess.onData((data) => {
          if (ws.readyState === ws.OPEN) {
            ws.send(JSON.stringify({ type: 'output', data: data }));
          }
        });
        
        termProcess.onExit(({ exitCode, signal }) => {
          logger.info(`Session ${sessionId} PTY exited: code=${exitCode}, signal=${signal}`);
          if (ws.readyState === ws.OPEN) {
            ws.send(JSON.stringify({ type: 'exit', exitCode, signal }));
          }
          this.sessions.delete(sessionId);
        });
        
      } catch (ptyError) {
        logger.warn(`PTY spawn failed, falling back: ${ptyError.message}`);
        usePty = false;
      }
    }
    
    if (!usePty) {
      // Fallback: use child_process with interactive shell
      termProcess = spawn(shell, ['-i'], {
        cwd: cwd,
        env: env,
        stdio: ['pipe', 'pipe', 'pipe']
      });
      
      termProcess.stdout.on('data', (data) => {
        if (ws.readyState === ws.OPEN) {
          ws.send(JSON.stringify({ type: 'output', data: data.toString() }));
        }
      });
      
      termProcess.stderr.on('data', (data) => {
        if (ws.readyState === ws.OPEN) {
          ws.send(JSON.stringify({ type: 'output', data: data.toString() }));
        }
      });
      
      termProcess.on('exit', (code, signal) => {
        logger.info(`Session ${sessionId} process exited: code=${code}, signal=${signal}`);
        if (ws.readyState === ws.OPEN) {
          ws.send(JSON.stringify({ type: 'exit', exitCode: code, signal }));
        }
        this.sessions.delete(sessionId);
      });
      
      termProcess.on('error', (err) => {
        logger.error(`Session ${sessionId} error: ${err.message}`);
        if (ws.readyState === ws.OPEN) {
          ws.send(JSON.stringify({ type: 'error', message: err.message }));
        }
      });
      
      // Mark this as non-pty for the write method
      termProcess._isPty = false;
    } else {
      termProcess._isPty = true;
    }
    
    // Store session
    this.sessions.set(sessionId, {
      id: sessionId,
      ws,
      process: termProcess,
      isPty: termProcess._isPty,
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
      if (session.isPty) {
        session.process.write(data);
      } else {
        session.process.stdin.write(data);
      }
      session.lastActivity = new Date();
    }
  }
  
  /**
   * Resize terminal
   */
  resize(sessionId, cols, rows) {
    const session = this.sessions.get(sessionId);
    if (session && session.isPty && session.process.resize) {
      session.process.resize(cols, rows);
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
        if (session.isPty) {
          session.process.kill();
        } else {
          session.process.kill('SIGTERM');
        }
      } catch (e) {
        // Process may already be dead
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
      lastActivity: session.lastActivity,
      isPty: session.isPty
    };
  }
  
  /**
   * Get all sessions info
   */
  getAllSessionInfo() {
    return Array.from(this.sessions.values()).map(s => ({
      id: s.id,
      clientIP: s.clientIP,
      createdAt: s.createdAt,
      lastActivity: s.lastActivity,
      isPty: s.isPty
    }));
  }
}
