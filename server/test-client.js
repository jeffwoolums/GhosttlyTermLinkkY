#!/usr/bin/env node
/**
 * Test Client for GhosttlyTermLinkkY Server
 * 
 * Tests the full flow: auth -> WebSocket -> terminal
 * 
 * Usage: node test-client.js [auth-token]
 */

import WebSocket from 'ws';

const SERVER_IP = process.env.SERVER_IP || '100.70.5.93';
const SERVER_PORT = process.env.SERVER_PORT || 3847;
const AUTH_TOKEN = process.argv[2] || process.env.AUTH_TOKEN || 'e0767826405ee440c93cb239b30159c6f88311c0270789e3';

console.log('');
console.log('👻 GhosttlyTermLinkkY Test Client');
console.log('═'.repeat(50));
console.log(`Server: ${SERVER_IP}:${SERVER_PORT}`);
console.log('');

async function main() {
  // Step 1: Authenticate
  console.log('📡 Step 1: Authenticating...');
  
  const authResponse = await fetch(`http://${SERVER_IP}:${SERVER_PORT}/auth`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token: AUTH_TOKEN })
  });
  
  if (!authResponse.ok) {
    console.error('❌ Auth failed:', await authResponse.text());
    process.exit(1);
  }
  
  const { sessionToken } = await authResponse.json();
  console.log('✅ Authenticated! Got session token');
  console.log('');
  
  // Step 2: Connect WebSocket
  console.log('🔌 Step 2: Connecting WebSocket...');
  
  const ws = new WebSocket(`ws://${SERVER_IP}:${SERVER_PORT}/terminal`);
  
  ws.on('open', () => {
    console.log('✅ WebSocket connected!');
    console.log('');
    
    // Step 3: Send auth message
    console.log('🔑 Step 3: Authenticating WebSocket...');
    ws.send(JSON.stringify({
      type: 'auth',
      token: sessionToken,
      cols: 80,
      rows: 24
    }));
  });
  
  let authenticated = false;
  let commandsSent = 0;
  
  ws.on('message', (data) => {
    const msg = JSON.parse(data.toString());
    
    if (msg.type === 'auth_success') {
      authenticated = true;
      console.log('✅ WebSocket authenticated!');
      console.log(`   Hostname: ${msg.hostname}`);
      console.log(`   Session:  ${msg.sessionId.slice(0, 8)}...`);
      console.log('');
      console.log('📺 Terminal output:');
      console.log('─'.repeat(50));
      
      // Send a few test commands
      setTimeout(() => {
        ws.send(JSON.stringify({ type: 'input', data: 'echo "👻 Hello from GhosttlyTermLinkkY!"\n' }));
        commandsSent++;
      }, 500);
      
      setTimeout(() => {
        ws.send(JSON.stringify({ type: 'input', data: 'pwd\n' }));
        commandsSent++;
      }, 1000);
      
      setTimeout(() => {
        ws.send(JSON.stringify({ type: 'input', data: 'which claude && claude --version 2>/dev/null | head -1\n' }));
        commandsSent++;
      }, 1500);
      
      // Close after test
      setTimeout(() => {
        console.log('');
        console.log('─'.repeat(50));
        console.log('');
        console.log('✅ Test complete! All systems working.');
        console.log('');
        console.log('📱 iOS App Connection Info:');
        console.log(`   URL: ws://${SERVER_IP}:${SERVER_PORT}/terminal`);
        console.log(`   Auth Token: ${AUTH_TOKEN}`);
        console.log('');
        ws.close();
        process.exit(0);
      }, 3000);
    }
    
    if (msg.type === 'auth_failed') {
      console.error('❌ WebSocket auth failed:', msg.message);
      ws.close();
      process.exit(1);
    }
    
    if (msg.type === 'output' && authenticated) {
      process.stdout.write(msg.data);
    }
    
    if (msg.type === 'error') {
      console.error('❌ Error:', msg.message);
    }
  });
  
  ws.on('error', (err) => {
    console.error('❌ WebSocket error:', err.message);
    process.exit(1);
  });
  
  ws.on('close', () => {
    if (!authenticated) {
      console.error('❌ Connection closed before auth');
      process.exit(1);
    }
  });
}

main().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});
