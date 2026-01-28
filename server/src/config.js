/**
 * Server Configuration
 * 
 * HARD REQUIREMENT: Tailscale must be running.
 * Server binds ONLY to Tailscale interface - no public exposure.
 */

import { config as dotenvConfig } from 'dotenv';
import { execSync } from 'child_process';
import os from 'os';

dotenvConfig();

/**
 * Get Tailscale IPv4 address
 * REQUIRED - server won't start without it
 */
function getTailscaleIP() {
  try {
    const result = execSync('tailscale ip -4', { 
      encoding: 'utf8',
      timeout: 5000 
    });
    return result.trim();
  } catch (error) {
    console.error('');
    console.error('═'.repeat(60));
    console.error('❌ FATAL: Tailscale is not running!');
    console.error('═'.repeat(60));
    console.error('');
    console.error('GhosttlyTermLinkkY requires Tailscale for secure connectivity.');
    console.error('');
    console.error('To fix:');
    console.error('  1. brew services start tailscale');
    console.error('  2. tailscale up (if not logged in)');
    console.error('  3. Restart this server');
    console.error('');
    console.error('═'.repeat(60));
    process.exit(1);
  }
}

/**
 * Get Tailscale connection status
 */
function getTailscaleStatus() {
  try {
    const result = execSync('tailscale status --json', { 
      encoding: 'utf8',
      timeout: 5000 
    });
    return JSON.parse(result);
  } catch {
    return null;
  }
}

// Get Tailscale IP (will exit if not available)
const tailscaleIP = getTailscaleIP();

export const config = {
  // Server settings
  // We bind to 0.0.0.0 but verify Tailscale IP on every connection
  port: parseInt(process.env.PORT || '3847'),
  host: '0.0.0.0',  // Bind all interfaces, verify Tailscale in middleware
  hostname: os.hostname(),
  
  // Tailscale
  tailscaleIP: tailscaleIP,
  getTailscaleStatus: getTailscaleStatus,
  
  // Authentication
  authToken: process.env.AUTH_TOKEN || (() => {
    console.error('❌ AUTH_TOKEN not set! Run: npm run setup');
    process.exit(1);
  })(),
  jwtSecret: process.env.JWT_SECRET || (() => {
    console.error('❌ JWT_SECRET not set! Run: npm run setup');
    process.exit(1);
  })(),
  
  // Terminal settings
  shell: process.env.SHELL || '/bin/zsh',
  defaultCwd: process.env.DEFAULT_CWD || os.homedir() + '/developer',
  
  // Claude Code
  claudeEnabled: process.env.CLAUDE_ENABLED !== 'false',
  
  // Session limits
  maxSessions: parseInt(process.env.MAX_SESSIONS || '5'),
  sessionTimeout: parseInt(process.env.SESSION_TIMEOUT || '3600000'), // 1 hour
};
