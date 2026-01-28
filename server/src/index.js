/**
 * GhosttlyTermLinkkY Server
 * 
 * WebSocket terminal server with tmux session persistence.
 * Tailscale-only connectivity.
 */

import { WebSocketServer } from "ws";
import http from "http";
import express from "express";
import { config } from "./config.js";
import { authMiddleware, generateToken, verifyToken } from "./middleware/auth.js";
import { TerminalManager, listTmuxSessions } from "./handlers/terminal.js";
import { logger } from "./utils/logger.js";
import { getDashboardHTML } from "./web-ui.js";
import { startDiscovery, stopDiscovery, getDiscoveryInfo } from "./discovery.js";

const terminalManager = new TerminalManager();

const app = express();
app.use(express.json());

// Dashboard
app.get("/", (req, res) => {
  const tsStatus = config.getTailscaleStatus();
  const status = {
    version: "1.1.0",
    hostname: config.hostname,
    tailscaleIP: config.tailscaleIP,
    shell: config.shell,
    activeSessions: terminalManager.getSessionCount(),
    maxSessions: config.maxSessions,
    claudeAvailable: config.claudeEnabled,
    uptime: process.uptime(),
    tailscale: { connected: tsStatus !== null },
    sessions: terminalManager.getAllSessionInfo(),
    tmuxSessions: listTmuxSessions(),
  };
  res.send(getDashboardHTML(status, { port: config.port, authToken: config.authToken }));
});

// Health
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    version: "1.1.0",
    hostname: config.hostname,
    tailscale: { ip: config.tailscaleIP, connected: config.getTailscaleStatus() !== null },
    uptime: process.uptime(),
    tmuxSessions: listTmuxSessions().length,
  });
});

function isTrustedConnection(ip) {
  if (ip.includes("100.")) return true;
  if (ip === "127.0.0.1" || ip === "::1" || ip === "::ffff:127.0.0.1") return true;
  return false;
}

// Auth
app.post("/auth", async (req, res) => {
  const { token } = req.body;
  const clientIP = req.ip || req.socket.remoteAddress;
  logger.info(`Auth attempt from ${clientIP}`);
  if (!isTrustedConnection(clientIP)) {
    logger.warn(`Auth rejected - not from Tailscale: ${clientIP}`);
    return res.status(403).json({ error: "Must connect via Tailscale" });
  }
  if (!token || token !== config.authToken) {
    logger.warn(`Auth failed - invalid token from ${clientIP}`);
    return res.status(401).json({ error: "Invalid token" });
  }
  const sessionToken = generateToken({ clientIP });
  logger.info(`Auth successful for ${clientIP}`);
  res.json({ sessionToken, expiresIn: "24h" });
});

// Status (auth required)
app.get("/status", authMiddleware, (req, res) => {
  res.json({
    hostname: config.hostname,
    shell: config.shell,
    activeSessions: terminalManager.getSessionCount(),
    maxSessions: config.maxSessions,
    claudeAvailable: config.claudeEnabled,
    tailscaleIP: config.tailscaleIP,
  });
});

// Tmux sessions list (auth required)
app.get("/sessions", authMiddleware, (req, res) => {
  const tmux = listTmuxSessions();
  const active = terminalManager.getAllSessionInfo();
  res.json({
    tmuxSessions: tmux,
    activeSessions: active,
  });
});

// Discovery
app.get("/discover", (req, res) => {
  res.json(getDiscoveryInfo(config.port, config.tailscaleIP));
});

// HTTP server
const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: "/terminal" });

// WebSocket handler
wss.on("connection", async (ws, req) => {
  const clientIP = req.socket.remoteAddress;

  if (!isTrustedConnection(clientIP)) {
    logger.warn(`WS rejected - not Tailscale: ${clientIP}`);
    ws.close(4003, "Must connect via Tailscale");
    return;
  }

  logger.info(`New connection from ${clientIP}`);
  let authenticated = false;
  let sessionId = null;

  const authTimeout = setTimeout(() => {
    if (!authenticated) ws.close(4001, "Auth timeout");
  }, 10000);

  ws.on("message", async (data) => {
    try {
      const msg = JSON.parse(data.toString());

      if (msg.type === "auth") {
        const verified = verifyToken(msg.token);
        if (verified) {
          clearTimeout(authTimeout);
          authenticated = true;

          sessionId = terminalManager.createSession(ws, {
            clientIP,
            shell: msg.shell || config.shell,
            cwd: msg.cwd || config.defaultCwd,
            cols: msg.cols || 80,
            rows: msg.rows || 24,
            tmuxSession: msg.tmuxSession || null,
            env: msg.env || {},
          });

          ws.send(JSON.stringify({
            type: "auth_success",
            sessionId,
            hostname: config.hostname,
            tailscaleIP: config.tailscaleIP,
            tmuxSession: msg.tmuxSession || null,
            message: `Connected to ${config.hostname} via Tailscale`,
          }));

          logger.info(`Session ${sessionId} started${msg.tmuxSession ? ` (tmux: ${msg.tmuxSession})` : ""}`);
        } else {
          ws.send(JSON.stringify({ type: "auth_failed", message: "Invalid token" }));
          ws.close(4001, "Auth failed");
        }
        return;
      }

      if (!authenticated) {
        ws.send(JSON.stringify({ type: "error", message: "Not authenticated" }));
        return;
      }

      if (msg.type === "input") {
        terminalManager.write(sessionId, msg.data);
      } else if (msg.type === "resize") {
        terminalManager.resize(sessionId, msg.cols, msg.rows);
      } else if (msg.type === "command") {
        handleCommand(sessionId, msg.command, ws);
      }
    } catch (err) {
      logger.error(`Message error: ${err.message}`);
      ws.send(JSON.stringify({ type: "error", message: `Invalid message: ${err.message}` }));
    }
  });

  ws.on("close", () => {
    clearTimeout(authTimeout);
    if (sessionId) {
      terminalManager.destroySession(sessionId);
      logger.info(`Session ${sessionId} closed`);
    }
  });

  ws.on("error", (err) => logger.error(`WS error: ${err.message}`));
});

function handleCommand(sessionId, command, ws) {
  switch (command) {
    case "claude":
      terminalManager.write(sessionId, "claude\n");
      break;
    case "interrupt":
      terminalManager.write(sessionId, "\x03");
      break;
    case "clear":
      terminalManager.write(sessionId, "\x1b[2J\x1b[H");
      break;
    case "sessions":
      ws.send(JSON.stringify({ type: "sessions", data: listTmuxSessions() }));
      break;
    default:
      ws.send(JSON.stringify({ type: "error", message: `Unknown: ${command}` }));
  }
}

// Start server
const PORT = config.port;
const HOST = config.host;

server.listen(PORT, HOST, () => {
  logger.info("═".repeat(55));
  logger.info("👻 GhosttlyTermLinkkY Server v1.1.0");
  logger.info("═".repeat(55));
  logger.info(`Tailscale IP:  ${config.tailscaleIP}`);
  logger.info(`HTTP:          http://${config.tailscaleIP}:${PORT}`);
  logger.info(`WebSocket:     ws://${config.tailscaleIP}:${PORT}/terminal`);
  logger.info(`Tmux:          ${listTmuxSessions().length} active sessions`);
  logger.info("═".repeat(55));
  logger.info("🔒 Connections verified via Tailscale");
  logger.info("═".repeat(55));

  startDiscovery(PORT, {
    version: "1.1.0",
    hostname: config.hostname,
    tailscaleIP: config.tailscaleIP,
    claudeEnabled: config.claudeEnabled,
    shell: config.shell,
  });
});

process.on("SIGINT", () => {
  logger.info("Shutting down...");
  stopDiscovery();
  terminalManager.destroyAll();
  server.close(() => process.exit(0));
});

process.on("SIGTERM", () => {
  logger.info("Terminating...");
  stopDiscovery();
  terminalManager.destroyAll();
  server.close(() => process.exit(0));
});
