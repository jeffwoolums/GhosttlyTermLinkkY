/**
 * Server Configuration
 */

import { config as dotenvConfig } from 'dotenv';
import { execSync } from 'child_process';
import os from 'os';

dotenvConfig();

// Try to get Tailscale IP
function getTailscaleIP() {
  try {
    const result = execSync('tailscale ip -4 2>/dev/null', { encoding: 'utf8' });
    return result.trim();
  } catch {
    return '100.x.x.x (run: tailscale ip -4)';
  }
}

export const config = {
  // Server settings
  port: parseInt(process.env.PORT || '3847'),
  host: process.env.HOST || '0.0.0.0',
  hostname: os.hostname(),
  
  // Tailscale
  tailscaleIP: getTailscaleIP(),
  
  // Authentication
  authToken: process.env.AUTH_TOKEN || 'ghosttly-dev-token',
  jwtSecret: process.env.JWT_SECRET || 'ghosttly-jwt-secret-change-me',
  
  // Terminal settings
  shell: process.env.SHELL || '/bin/zsh',
  defaultCwd: process.env.DEFAULT_CWD || os.homedir() + '/developer',
  
  // Claude Code
  claudeEnabled: process.env.CLAUDE_ENABLED !== 'false',
  
  // Session limits
  maxSessions: parseInt(process.env.MAX_SESSIONS || '5'),
  sessionTimeout: parseInt(process.env.SESSION_TIMEOUT || '3600000'), // 1 hour
};
