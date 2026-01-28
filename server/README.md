# 👻 GhosttlyTermLinkkY Server

WebSocket terminal server for iOS-to-Mac remote development via Tailscale.

## Quick Start

```bash
cd server
npm install
npm run setup  # First time only - generates auth token
npm start
```

## Connection Info

Once running, the server displays connection info:

```
═══════════════════════════════════════════════════════
👻 GhosttlyTermLinkkY Server
═══════════════════════════════════════════════════════
Tailscale IP:  100.70.5.93
HTTP:          http://100.70.5.93:3847
WebSocket:     ws://100.70.5.93:3847/terminal
═══════════════════════════════════════════════════════
🔒 Connections verified via Tailscale
═══════════════════════════════════════════════════════
```

## Web Dashboard

Open `http://100.70.5.93:3847` in a browser to see:
- Server status
- Active sessions
- Connection info
- Auth token (for iOS app)

## iOS App Configuration

In the iOS app, configure:
- **Host:** `100.70.5.93` (your Mac's Tailscale IP)
- **Port:** `3847`
- **Auth Token:** (shown in dashboard or .env file)

## Auto-Start (LaunchAgent)

To start automatically on login:

```bash
# Install
cp com.ghosttly.termlinky-server.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.ghosttly.termlinky-server.plist

# Check status
launchctl list | grep ghosttly

# View logs
tail -f ~/Library/Logs/termlinky-server.log

# Stop/Unload
launchctl unload ~/Library/LaunchAgents/com.ghosttly.termlinky-server.plist
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Web dashboard |
| `/health` | GET | Health check JSON |
| `/auth` | POST | Exchange auth token for session JWT |
| `/status` | GET | Server status (requires auth) |
| `/terminal` | WS | WebSocket terminal connection |

## Authentication Flow

1. **Get Session Token:**
   ```bash
   curl -X POST http://100.70.5.93:3847/auth \
     -H "Content-Type: application/json" \
     -d '{"token":"YOUR_AUTH_TOKEN"}'
   ```

2. **Connect WebSocket:**
   ```javascript
   ws = new WebSocket('ws://100.70.5.93:3847/terminal');
   ws.send(JSON.stringify({ 
     type: 'auth', 
     token: sessionToken,
     cols: 80,
     rows: 24
   }));
   ```

3. **Send Commands:**
   ```javascript
   ws.send(JSON.stringify({ type: 'input', data: 'ls -la\n' }));
   ```

## WebSocket Messages

### Client → Server

| Type | Fields | Description |
|------|--------|-------------|
| `auth` | `token, cols, rows` | Authenticate session |
| `input` | `data` | Send terminal input |
| `resize` | `cols, rows` | Resize terminal |
| `command` | `command` | Special command (claude, interrupt, clear) |

### Server → Client

| Type | Fields | Description |
|------|--------|-------------|
| `auth_success` | `sessionId, hostname` | Auth successful |
| `auth_failed` | `message` | Auth failed |
| `output` | `data` | Terminal output |
| `exit` | `exitCode, signal` | Terminal exited |
| `error` | `message` | Error message |

## Security

- **Tailscale Required:** Server verifies all connections come from Tailscale network (100.x.x.x)
- **Token Auth:** Pre-shared token required to get session JWT
- **JWT Sessions:** 24-hour expiring session tokens
- **No Public Exposure:** Only accessible via Tailscale VPN

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3847` | Server port |
| `AUTH_TOKEN` | (generated) | Pre-shared auth token |
| `JWT_SECRET` | (generated) | JWT signing secret |
| `SHELL` | `/bin/zsh` | Default shell |
| `DEFAULT_CWD` | `~/developer` | Default working directory |
| `MAX_SESSIONS` | `5` | Maximum concurrent sessions |
| `CLAUDE_ENABLED` | `true` | Enable Claude Code integration |

## Testing

```bash
# Run test client
node test-client.js

# Or with custom server
SERVER_IP=100.70.5.93 node test-client.js
```

## Files

```
server/
├── src/
│   ├── index.js           # Main server
│   ├── config.js          # Configuration
│   ├── web-ui.js          # Dashboard HTML
│   ├── handlers/
│   │   └── terminal.js    # PTY/terminal management
│   ├── middleware/
│   │   └── auth.js        # JWT authentication
│   └── utils/
│       └── logger.js      # Logging
├── .env                   # Configuration (generated)
├── package.json
├── test-client.js         # Test client
└── com.ghosttly.termlinky-server.plist  # LaunchAgent
```

## Troubleshooting

**Server won't start:**
- Check Tailscale is running: `tailscale status`
- Check port isn't in use: `lsof -i :3847`
- View logs: `npm start` or check `~/Library/Logs/termlinky-server.log`

**Can't connect from iOS:**
- Verify both devices on Tailscale: `tailscale status`
- Check Mac firewall allows connections
- Verify auth token matches

**PTY issues:**
- Server falls back to child_process if node-pty fails
- Rebuild node-pty: `npm rebuild node-pty`
