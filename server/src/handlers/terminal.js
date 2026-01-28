/**
 * Terminal Session Manager
 * 
 * Handles PTY creation with tmux session persistence.
 * Sessions survive client disconnects — reattach by name.
 */

import { spawn, execSync } from "child_process";
import { v4 as uuidv4 } from "uuid";
import { config } from "../config.js";
import { logger } from "../utils/logger.js";

let pty = null;
let usePty = false;

try {
  const ptyModule = await import("node-pty");
  pty = ptyModule.default;
  usePty = true;
  logger.info("Using node-pty for terminal sessions");
} catch (e) {
  logger.warn(`node-pty not available, using child_process fallback: ${e.message}`);
}

function tmuxSessionExists(name) {
  try {
    execSync(`tmux has-session -t "${name}" 2>/dev/null`, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

export function listTmuxSessions() {
  try {
    const output = execSync(
      `tmux list-sessions -F "#{session_name}|#{session_created}|#{session_attached}"`,
      { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }
    ).trim();
    if (!output) return [];
    return output.split("\n").map((line) => {
      const [name, created, attached] = line.split("|");
      return { name, created: new Date(parseInt(created) * 1000).toISOString(), attached: attached === "1" };
    });
  } catch {
    return [];
  }
}

export class TerminalManager {
  constructor() {
    this.sessions = new Map();
  }

  createSession(ws, options = {}) {
    if (this.sessions.size >= config.maxSessions) {
      throw new Error("Maximum session limit reached");
    }

    const sessionId = uuidv4();
    const cwd = options.cwd || config.defaultCwd;
    const tmuxName = options.tmuxSession || null;

    const env = {
      ...process.env,
      TERM: "xterm-256color",
      COLORTERM: "truecolor",
      GHOSTTLY_SESSION: sessionId,
    };

    let command, args;

    if (tmuxName) {
      if (tmuxSessionExists(tmuxName)) {
        logger.info(`Attaching to existing tmux session: ${tmuxName}`);
        command = "tmux";
        args = ["attach-session", "-t", tmuxName];
      } else {
        logger.info(`Creating new tmux session: ${tmuxName}`);
        command = "tmux";
        args = ["new-session", "-s", tmuxName, "-c", cwd];
      }
    } else {
      command = options.shell || config.shell;
      args = [];
      logger.info(`Creating bare shell session: ${command}`);
    }

    let termProcess;

    if (usePty) {
      try {
        termProcess = pty.spawn(command, args, {
          name: "xterm-256color",
          cols: options.cols || 80,
          rows: options.rows || 24,
          cwd: cwd,
          env: env,
        });

        termProcess.onData((data) => {
          if (ws.readyState === ws.OPEN) {
            ws.send(JSON.stringify({ type: "output", data: data }));
          }
        });

        termProcess.onExit(({ exitCode, signal }) => {
          logger.info(`Session ${sessionId} PTY exited: code=${exitCode}, signal=${signal}`);
          if (ws.readyState === ws.OPEN) {
            ws.send(JSON.stringify({ type: "exit", exitCode, signal }));
          }
          this.sessions.delete(sessionId);
        });

        termProcess._isPty = true;
      } catch (ptyError) {
        logger.warn(`PTY spawn failed, falling back: ${ptyError.message}`);
        usePty = false;
      }
    }

    if (!usePty) {
      termProcess = spawn(command, args, { cwd, env, stdio: ["pipe", "pipe", "pipe"] });

      const sendOutput = (data) => {
        if (ws.readyState === ws.OPEN) {
          ws.send(JSON.stringify({ type: "output", data: data.toString() }));
        }
      };

      termProcess.stdout.on("data", sendOutput);
      termProcess.stderr.on("data", sendOutput);

      termProcess.on("exit", (code, signal) => {
        logger.info(`Session ${sessionId} exited: code=${code}, signal=${signal}`);
        if (ws.readyState === ws.OPEN) {
          ws.send(JSON.stringify({ type: "exit", exitCode: code, signal }));
        }
        this.sessions.delete(sessionId);
      });

      termProcess.on("error", (err) => {
        logger.error(`Session ${sessionId} error: ${err.message}`);
        if (ws.readyState === ws.OPEN) {
          ws.send(JSON.stringify({ type: "error", message: err.message }));
        }
      });

      termProcess._isPty = false;
    }

    this.sessions.set(sessionId, {
      id: sessionId,
      ws,
      process: termProcess,
      isPty: termProcess._isPty,
      tmuxSession: tmuxName,
      clientIP: options.clientIP,
      createdAt: new Date(),
      lastActivity: new Date(),
    });

    return sessionId;
  }

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

  resize(sessionId, cols, rows) {
    const session = this.sessions.get(sessionId);
    if (session && session.isPty && session.process.resize) {
      session.process.resize(cols, rows);
    }
  }

  destroySession(sessionId) {
    const session = this.sessions.get(sessionId);
    if (session) {
      try {
        session.isPty ? session.process.kill() : session.process.kill("SIGTERM");
      } catch (e) {}
      this.sessions.delete(sessionId);
      logger.info(`Session ${sessionId} destroyed`);
    }
  }

  destroyAll() {
    for (const sessionId of this.sessions.keys()) {
      this.destroySession(sessionId);
    }
  }

  getSessionCount() {
    return this.sessions.size;
  }

  getSessionInfo(sessionId) {
    const session = this.sessions.get(sessionId);
    if (!session) return null;
    return {
      id: session.id,
      tmuxSession: session.tmuxSession,
      clientIP: session.clientIP,
      createdAt: session.createdAt,
      lastActivity: session.lastActivity,
      isPty: session.isPty,
    };
  }

  getAllSessionInfo() {
    return Array.from(this.sessions.values()).map((s) => ({
      id: s.id,
      tmuxSession: s.tmuxSession,
      clientIP: s.clientIP,
      createdAt: s.createdAt,
      lastActivity: s.lastActivity,
      isPty: s.isPty,
    }));
  }
}
