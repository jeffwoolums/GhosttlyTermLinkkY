# GhosttlyTermLinkkY Server

WebSocket-based terminal server for remote iOS-to-Mac development via Tailscale.

## Quick Start

```bash
# Install dependencies
npm install

# Generate secure tokens (first time only)
npm run setup

# Start the server
npm start
```

## Configuration

After running `npm run setup`, a `.env` file is created with:

- **AUTH_TOKEN** - Master token for authentication (give this to iOS app)
- **JWT_SECRET** - Secret for signing session tokens
- **PORT** - Server port (default: 3847)
- **SHELL** - Default shell (default: /bin/zsh)
- **DEFAULT_CWD** - Starting directory

## API Endpoints

### REST

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/auth` | Get session token |
| GET | `/status` | Server status (auth required) |

### WebSocket

Connect to `ws://HOST:PORT/terminal`

#### Message Types (Client → Server)

```json
// Authentication (send first)
{"type": "auth", "token": "session_token"}

// Terminal input
{"type": "input", "data": "ls -la\\n"}

// Resize terminal
{"type": "resize", "cols": 80, "rows": 24}

// Special commands
{"type": "command", "command": "claude"}
{"type": "command", "command": "interrupt"}
{"type": "command", "command": "clear"}
```

#### Message Types (Server → Client)

```json
// Auth success
{"type": "auth_success", "sessionId": "...", "message": "..."}

// Terminal output
{"type": "output", "data": "terminal output here"}

// Shell exited
{"type": "exit", "exitCode": 0, "signal": null}

// Error
{"type": "error", "message": "error description"}
```

## Usage with Tailscale

1. Ensure Tailscale is running on both Mac and iOS device
2. Get your Mac's Tailscale IP: `tailscale ip -4`
3. Connect from iOS to: `ws://100.x.x.x:3847/terminal`

## Running as a Service (launchd)

Create `~/Library/LaunchAgents/com.ghosttly.server.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ghosttly.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/node</string>
        <string>/Users/clawdbot/developer/GhosttlyTermLinkkY/server/src/index.js</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/clawdbot/developer/GhosttlyTermLinkkY/server</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/ghosttly-server.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/ghosttly-server.err</string>
</dict>
</plist>
```

Then:
```bash
launchctl load ~/Library/LaunchAgents/com.ghosttly.server.plist
```

## Testing

```bash
# Test health endpoint
curl http://localhost:3847/health

# Test authentication
curl -X POST http://localhost:3847/auth \
  -H "Content-Type: application/json" \
  -d '{"token": "YOUR_AUTH_TOKEN"}'

# Interactive test client
node test-client.js
```

## Security Notes

- Never commit `.env` file (contains secrets)
- The AUTH_TOKEN grants full terminal access - treat it like a password
- Consider restricting to Tailscale IPs only in production
- Use HTTPS in production (with reverse proxy or TLS)
