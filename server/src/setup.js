/**
 * Setup Script
 * 
 * Generates secure tokens and creates .env file
 */

import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function generateSecureToken(length = 32) {
  return crypto.randomBytes(length).toString('hex');
}

const authToken = generateSecureToken(24);
const jwtSecret = generateSecureToken(32);

const envContent = `# GhosttlyTermLinkkY Server Configuration
# Generated: ${new Date().toISOString()}

# Server
PORT=3847
HOST=0.0.0.0

# Authentication - KEEP THESE SECRET!
AUTH_TOKEN=${authToken}
JWT_SECRET=${jwtSecret}

# Terminal
SHELL=/bin/zsh
DEFAULT_CWD=${process.env.HOME}/developer

# Limits
MAX_SESSIONS=5
SESSION_TIMEOUT=3600000

# Features
CLAUDE_ENABLED=true
`;

const envPath = path.join(__dirname, '..', '.env');

// Check if .env already exists
if (fs.existsSync(envPath)) {
  console.log('⚠️  .env file already exists!');
  console.log('   Delete it first if you want to regenerate tokens.');
  process.exit(1);
}

fs.writeFileSync(envPath, envContent);

console.log('');
console.log('═'.repeat(60));
console.log('👻 GhosttlyTermLinkkY Setup Complete');
console.log('═'.repeat(60));
console.log('');
console.log('Configuration saved to .env');
console.log('');
console.log('🔑 Your Auth Token (save this for the iOS app):');
console.log('');
console.log(`   ${authToken}`);
console.log('');
console.log('⚠️  Keep this token secret! Anyone with it can access your terminal.');
console.log('');
console.log('Next steps:');
console.log('  1. npm install');
console.log('  2. npm start');
console.log('  3. Configure your iOS app with the auth token');
console.log('');
console.log('═'.repeat(60));
