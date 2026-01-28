/**
 * Test Client for GhosttlyTermLinkkY
 * 
 * Usage: node test-client.js
 */

import WebSocket from 'ws';
import readline from 'readline';
import { config } from './src/config.js';

const AUTH_TOKEN = process.env.AUTH_TOKEN || config.authToken;
const SERVER_URL = process.env.SERVER_URL || 'ws://localhost:3847/terminal';

console.log('👻 GhosttlyTermLinkkY Test Client');
console.log('================================');
console.log(`Connecting to: ${SERVER_URL}`);
console.log('');

// Get session token first
async function getSessionToken() {
  const res = await fetch('http://localhost:3847/auth', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token: AUTH_TOKEN })
  });
  
  if (!res.ok) {
    throw new Error(`Auth failed: ${res.status}`);
  }
  
  const { sessionToken } = await res.json();
  return sessionToken;
}

async function main() {
  try {
    const sessionToken = await getSessionToken();
    console.log('✅ Got session token');
    
    const ws = new WebSocket(SERVER_URL);
    
    ws.on('open', () => {
      console.log('✅ WebSocket connected');
      console.log('');
      
      // Authenticate
      ws.send(JSON.stringify({
        type: 'auth',
        token: sessionToken
      }));
    });
    
    ws.on('message', (data) => {
      const msg = JSON.parse(data.toString());
      
      if (msg.type === 'auth_success') {
        console.log(`✅ Authenticated: ${msg.message}`);
        console.log('');
        console.log('Type commands below (Ctrl+C to exit):');
        console.log('');
        startInput(ws);
      } else if (msg.type === 'output') {
        process.stdout.write(msg.data);
      } else if (msg.type === 'exit') {
        console.log(`\n[Shell exited: ${msg.exitCode}]`);
        process.exit(0);
      } else if (msg.type === 'error') {
        console.error(`Error: ${msg.message}`);
      }
    });
    
    ws.on('close', () => {
      console.log('\nConnection closed');
      process.exit(0);
    });
    
    ws.on('error', (err) => {
      console.error(`WebSocket error: ${err.message}`);
      process.exit(1);
    });
    
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  }
}

function startInput(ws) {
  // Set up raw mode for proper terminal handling
  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true);
  }
  process.stdin.resume();
  
  process.stdin.on('data', (data) => {
    // Ctrl+C locally exits
    if (data[0] === 3) {
      ws.close();
      process.exit(0);
    }
    
    ws.send(JSON.stringify({
      type: 'input',
      data: data.toString()
    }));
  });
}

main();
