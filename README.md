# 👻 GhosttlyTermLinkkY

> Ghostly remote app for Claude Code in terminal for iOS to Mac dev rig remote with Tailscale. Dev from anywhere.

<p align="center">
  <img src="docs/screenshot.png" width="300" alt="GhosttlyTermLinkkY Screenshot">
</p>

## 🎯 What is this?

GhosttlyTermLinkkY is an iOS app that lets you connect to your Mac development machine via Tailscale and run Claude Code (or any terminal commands) remotely. It's your mobile companion for coding on the go.

**Use cases:**
- 📱 Run Claude Code on your Mac from your iPhone/iPad
- 🔧 Quick terminal access to your dev machine while away
- 🚀 Deploy, debug, or check logs from anywhere
- ☕ Code from a coffee shop without bringing your laptop

## ✨ Features

- **🔗 Tailscale Integration** - Secure connection to your Mac via Tailscale VPN
- **💻 Full Terminal** - Real terminal emulator with command history
- **⚡ Quick Commands** - One-tap access to common commands (claude, git, npm, etc.)
- **🌙 Dark Mode** - Easy on the eyes, built for terminal vibes
- **📱 iOS Native** - Built with SwiftUI for a smooth, native experience
- **🔒 Secure** - SSH authentication (password or key-based)

## 🚀 Getting Started

### Prerequisites

1. **Tailscale** installed on both:
   - Your Mac (dev machine)
   - Your iOS device
   
2. **SSH enabled** on your Mac:
   ```bash
   # Enable Remote Login in System Settings > General > Sharing
   # Or via terminal:
   sudo systemsetup -setremotelogin on
   ```

3. **Claude Code** (optional but recommended):
   ```bash
   # Install on your Mac
   npm install -g @anthropic-ai/claude-code
   ```

### Installation

#### Option 1: Build from Source (Xcode)

1. Clone this repo:
   ```bash
   git clone https://github.com/jeffwoolums/GhosttlyTermLinkkY.git
   ```

2. Open in Xcode:
   ```bash
   cd GhosttlyTermLinkkY
   open GhosttlyTermLinkkY.xcodeproj  # Coming soon
   # Or create a new Xcode project and import the Sources
   ```

3. Build and run on your iOS device

#### Option 2: TestFlight (Coming Soon)

We're working on TestFlight distribution. Stay tuned!

### Setup

1. **Launch the app** on your iOS device

2. **Add your Mac as a host:**
   - Go to **Hosts** tab
   - Tap **+ Add New Host**
   - Enter:
     - **Name:** My Mac (or whatever you want)
     - **Hostname:** Your Tailscale IP (100.x.x.x) or MagicDNS name
     - **Username:** Your Mac username
     - **Password:** Your Mac password (or use SSH key)

3. **Connect and code!**
   - Tap your host to connect
   - Use the terminal to run commands
   - Hit the ⚡ button for quick commands

## 📱 Screenshots

| Terminal | Hosts | Quick Commands |
|----------|-------|----------------|
| ![Terminal](docs/terminal.png) | ![Hosts](docs/hosts.png) | ![Commands](docs/commands.png) |

## 🏗️ Architecture

```
GhosttlyTermLinkkY/
├── Sources/
│   ├── App/
│   │   └── GhosttlyTermLinkkYApp.swift    # App entry point
│   ├── Views/
│   │   ├── ContentView.swift              # Main tab view
│   │   ├── TerminalView.swift             # Terminal UI
│   │   ├── HostsView.swift                # Host management
│   │   └── SettingsView.swift             # App settings
│   ├── Models/
│   │   ├── SSHHost.swift                  # Host configuration
│   │   ├── TerminalLine.swift             # Terminal output
│   │   └── QuickCommand.swift             # Quick command definitions
│   └── Services/
│       ├── ConnectionManager.swift        # Connection state management
│       ├── SSHService.swift               # SSH communication
│       ├── TerminalSession.swift          # Terminal session handling
│       └── SettingsManager.swift          # User preferences
```

## 🔧 Development

### Requirements

- Xcode 15+
- iOS 17+ deployment target
- Swift 5.9+

### Building

```bash
# Clone
git clone https://github.com/jeffwoolums/GhosttlyTermLinkkY.git
cd GhosttlyTermLinkkY

# Open in Xcode
xed .

# Build & Run
# Select your iOS device/simulator and hit ⌘R
```

### SSH Library Integration

The current implementation uses a simulated SSH layer for UI development. For production:

**Option 1: Citadel (Pure Swift SSH2)**
```swift
// In Package.swift
.package(url: "https://github.com/orlandos-nl/Citadel.git", from: "0.7.0")
```

**Option 2: SSH Proxy Backend**
Run a lightweight WebSocket-to-SSH proxy on your Mac that the app connects to.

## 🛣️ Roadmap

- [x] Basic terminal UI
- [x] Host management
- [x] Quick commands
- [x] Settings persistence
- [ ] Real SSH integration (Citadel)
- [ ] SSH key authentication
- [ ] Multiple active sessions
- [ ] Session persistence
- [ ] File browser
- [ ] Code editor integration
- [ ] iPad split view support
- [ ] macOS Catalyst support

## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- [Tailscale](https://tailscale.com) - For making secure networking easy
- [Claude Code](https://github.com/anthropics/claude-code) - The AI coding assistant this was built for
- [Citadel](https://github.com/orlandos-nl/Citadel) - Pure Swift SSH implementation

---

<p align="center">
  Made with 👻 by <a href="https://github.com/jeffwoolums">@jeffwoolums</a>
</p>
