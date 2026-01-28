/**
 * GhosttlyTermLinkkY Server
 * 
 * WebSocket terminal server for iOS-to-Mac remote development via Tailscale
 * 
 * Features:
 * - Secure WebSocket connections
 * - PTY-based shell access
 * - Token authentication
 * - Claude Code integration ready
 */

import { WebSocketServer } from 'ws';
import http from 'http';
import express from 'express';
import { config } from './config.js';
import { authMiddleware, generateToken, verifyToken } from './middleware/auth.js';
import { TerminalManager } from './handlers/terminal.js';
import { logger } from './utils/logger.js';

const app = express();
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    version: '1.0.0',
    hostname: config.hostname,
    uptime: process.uptime()
  });
});

// Auth endpoint - get a session token
app.post('/auth', async (req, res) => {
  const { token } = req.body;
  
  if (!token || token !== config.authToken) {
    logger.warn('Auth failed - invalid token');
    return res.status(401).json({ error: 'Invalid token' });
  }
  
  const sessionToken = generateToken();
  logger.info('Auth successful - session created');
  res.json({ sessionToken, expiresIn: '24h' });
});

// Status endpoint (authenticated)
app.get('/status', authMiddleware, (req, res) => {
  res.json({
    hostname: config.hostname,
    shell: config.shell,
    activeSessions: terminalManager.getSessionCount(),
    claudeAvailable: config.claudeEnabled
  });
});

// Create HTTP server
const server = http.createServer(app);

// Create WebSocket server
const wss = new WebSocketServer({ 
  server,
  path: '/terminal'
});

// Terminal session manager
const terminalManager = new TerminalManager();

// WebSocket connection handler
wss.on('connection', async (ws, req) => {
  const clientIP = req.socket.remoteAddress;
  logger.info(`New WebSocket connection from ${clientIP}`);
  
  // Expect auth message first
  let authenticated = false;
  let sessionId = null;
  
  ws.on('message', async (data) => {
    try {
      const message = JSON.parse(data.toString());
      
      // Handle authentication
      if (message.type === 'auth') {
        const verified = verifyToken(message.token);
        if (verified) {
          authenticated = true;
          sessionId = terminalManager.createSession(ws, {
            clientIP,
            shell: message.shell || config.shell,
            cwd: message.cwd || config.defaultCwd,
            env: message.env || {}
          });
          
          ws.send(JSON.stringify({
            type: 'auth_success',
            sessionId,
            message: 'Connected to GhosttlyTermLinkkY'
          }));
          
          logger.info(`Session ${sessionId} authenticated`);
        } else {
          ws.send(JSON.stringify({
            type: 'auth_failed',
            message: 'Invalid or expired token'
          }));
          ws.close();
        }
        return;
      }
      
      // Require authentication for all other messages
      if (!authenticated) {
        ws.send(JSON.stringify({
          type: 'error',
          message: 'Not authenticated'
        }));
        return;
      }
      
      // Handle terminal input
      if (message.type === 'input') {
        terminalManager.write(sessionId, message.data);
      }
      
      // Handle resize
      if (message.type === 'resize') {
        terminalManager.resize(sessionId, message.cols, message.rows);
      }
      
      // Handle special commands
      if (message.type === 'command') {
        handleCommand(sessionId, message.command, ws);
      }
      
    } catch (error) {
      logger.error(`Message parse error: ${error.message}`);
      ws.send(JSON.stringify({
        type: 'error',
        message: 'Invalid message format'
      }));
    }
  });
  
  ws.on('close', () => {
    if (sessionId) {
      terminalManager.destroySession(sessionId);
      logger.info(`Session ${sessionId} closed`);
    }
  });
  
  ws.on('error', (error) => {
    logger.error(`WebSocket error: ${error.message}`);
  });
});

// Handle special commands (claude, etc.)
function handleCommand(sessionId, command, ws) {
  switch (command) {
    case 'claude':
      // Launch Claude Code in the terminal
      terminalManager.write(sessionId, 'claude\n');
      break;
    case 'interrupt':
      // Send Ctrl+C
      terminalManager.write(sessionId, '\x03');
      break;
    case 'clear':
      // Clear screen
      terminalManager.write(sessionId, '\x1b[2J\x1b[H');
      break;
    default:
      ws.send(JSON.stringify({
        type: 'error',
        message: `Unknown command: ${command}`
      }));
  }
}

// Start server
const PORT = config.port;
const HOST = config.host;

server.listen(PORT, HOST, () => {
  logger.info('═'.repeat(50));
  logger.info('👻 GhosttlyTermLinkkY Server Started');
  logger.info('═'.repeat(50));
  logger.info(`HTTP/WS: http://${HOST}:${PORT}`);
  logger.info(`Terminal WS: ws://${HOST}:${PORT}/terminal`);
  logger.info(`Tailscale: ${config.tailscaleIP}:${PORT}`);
  logger.info('═'.repeat(50));
});

// Graceful shutdown
process.on('SIGINT', () => {
  logger.info('Shutting down...');
  terminalManager.destroyAll();
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});
