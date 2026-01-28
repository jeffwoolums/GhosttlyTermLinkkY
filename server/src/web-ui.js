/**
 * Web UI Dashboard
 * 
 * Simple status and configuration interface
 */

export function getDashboardHTML(status, config) {
  const sessionRows = status.sessions?.map(s => `
    <tr>
      <td class="mono">${s.id.slice(0, 8)}...</td>
      <td>${s.clientIP}</td>
      <td>${formatDuration(Date.now() - new Date(s.createdAt).getTime())}</td>
      <td>${formatDuration(Date.now() - new Date(s.lastActivity).getTime())} ago</td>
    </tr>
  `).join('') || '<tr><td colspan="4" style="text-align:center;opacity:0.6">No active sessions</td></tr>';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>👻 GhosttlyTermLinkkY</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
      background: #0d1117;
      color: #c9d1d9;
      min-height: 100vh;
      padding: 2rem;
    }
    .container { max-width: 900px; margin: 0 auto; }
    header {
      display: flex;
      align-items: center;
      gap: 1rem;
      margin-bottom: 2rem;
    }
    h1 { font-size: 2rem; font-weight: 600; }
    .ghost { font-size: 2.5rem; }
    .badge {
      background: #238636;
      color: white;
      padding: 0.25rem 0.75rem;
      border-radius: 20px;
      font-size: 0.75rem;
      font-weight: 500;
    }
    .badge.warning { background: #9e6a03; }
    .card {
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 12px;
      padding: 1.5rem;
      margin-bottom: 1.5rem;
    }
    .card h2 {
      font-size: 1rem;
      color: #8b949e;
      margin-bottom: 1rem;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 1rem;
    }
    .stat {
      background: #0d1117;
      padding: 1rem;
      border-radius: 8px;
      text-align: center;
    }
    .stat-value {
      font-size: 1.75rem;
      font-weight: 700;
      color: #58a6ff;
    }
    .stat-label {
      font-size: 0.75rem;
      color: #8b949e;
      margin-top: 0.25rem;
    }
    .mono {
      font-family: 'SF Mono', Monaco, Consolas, monospace;
      font-size: 0.9rem;
    }
    table {
      width: 100%;
      border-collapse: collapse;
    }
    th, td {
      padding: 0.75rem;
      text-align: left;
      border-bottom: 1px solid #30363d;
    }
    th { color: #8b949e; font-weight: 500; }
    .info-grid {
      display: grid;
      grid-template-columns: 150px 1fr;
      gap: 0.5rem 1rem;
    }
    .info-label { color: #8b949e; }
    .info-value { font-family: 'SF Mono', Monaco, monospace; }
    .token-box {
      background: #0d1117;
      padding: 1rem;
      border-radius: 8px;
      font-family: 'SF Mono', Monaco, monospace;
      font-size: 0.85rem;
      word-break: break-all;
      position: relative;
    }
    .copy-btn {
      position: absolute;
      top: 0.5rem;
      right: 0.5rem;
      background: #21262d;
      border: 1px solid #30363d;
      color: #c9d1d9;
      padding: 0.25rem 0.5rem;
      border-radius: 6px;
      cursor: pointer;
      font-size: 0.75rem;
    }
    .copy-btn:hover { background: #30363d; }
    footer {
      text-align: center;
      color: #484f58;
      font-size: 0.85rem;
      margin-top: 2rem;
    }
    .refresh { color: #58a6ff; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <span class="ghost">👻</span>
      <h1>GhosttlyTermLinkkY</h1>
      <span class="badge">${status.tailscale?.connected ? '🔗 Tailscale' : '⚠️ No Tailscale'}</span>
    </header>
    
    <div class="card">
      <h2>📊 Server Status</h2>
      <div class="stats">
        <div class="stat">
          <div class="stat-value">${status.activeSessions || 0}/${status.maxSessions || 5}</div>
          <div class="stat-label">Active Sessions</div>
        </div>
        <div class="stat">
          <div class="stat-value">${formatDuration(status.uptime * 1000)}</div>
          <div class="stat-label">Uptime</div>
        </div>
        <div class="stat">
          <div class="stat-value">${status.claudeAvailable ? '✅' : '❌'}</div>
          <div class="stat-label">Claude Code</div>
        </div>
        <div class="stat">
          <div class="stat-value">${status.version || '1.0.0'}</div>
          <div class="stat-label">Version</div>
        </div>
      </div>
    </div>
    
    <div class="card">
      <h2>🖥️ Connection Info</h2>
      <div class="info-grid">
        <span class="info-label">Hostname</span>
        <span class="info-value">${status.hostname}</span>
        <span class="info-label">Tailscale IP</span>
        <span class="info-value">${status.tailscaleIP}</span>
        <span class="info-label">WebSocket URL</span>
        <span class="info-value">ws://${status.tailscaleIP}:${config.port}/terminal</span>
        <span class="info-label">Shell</span>
        <span class="info-value">${status.shell}</span>
      </div>
    </div>
    
    <div class="card">
      <h2>🔑 Auth Token (for iOS app)</h2>
      <div class="token-box">
        <button class="copy-btn" onclick="copyToken()">Copy</button>
        <span id="token">${config.authToken}</span>
      </div>
    </div>
    
    <div class="card">
      <h2>📡 Active Sessions</h2>
      <table>
        <thead>
          <tr>
            <th>Session ID</th>
            <th>Client IP</th>
            <th>Duration</th>
            <th>Last Activity</th>
          </tr>
        </thead>
        <tbody>
          ${sessionRows}
        </tbody>
      </table>
    </div>
    
    <footer>
      <a href="/" class="refresh">↻ Refresh</a> · 
      Secured via Tailscale · 
      <a href="/health" class="refresh">API Health</a>
    </footer>
  </div>
  
  <script>
    function copyToken() {
      const token = document.getElementById('token').textContent;
      navigator.clipboard.writeText(token);
      document.querySelector('.copy-btn').textContent = 'Copied!';
      setTimeout(() => document.querySelector('.copy-btn').textContent = 'Copy', 2000);
    }
    // Auto-refresh every 30s
    setTimeout(() => location.reload(), 30000);
  </script>
</body>
</html>`;
}

function formatDuration(ms) {
  const seconds = Math.floor(ms / 1000);
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ${minutes % 60}m`;
  const days = Math.floor(hours / 24);
  return `${days}d ${hours % 24}h`;
}
