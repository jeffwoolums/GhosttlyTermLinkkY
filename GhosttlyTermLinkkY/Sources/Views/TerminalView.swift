//
//  TerminalView.swift
//  GhosttlyTermLinkkY
//
//  Main terminal interface with ANSI color rendering.
//

import SwiftUI

struct TerminalView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var terminalSession = TerminalSession()
    @State private var inputText: String = ""
    @State private var showingQuickCommands = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !connectionManager.isConnected && terminalSession.outputLines.isEmpty {
                    WelcomeView(connectionManager: connectionManager)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Spacer()
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(terminalSession.outputLines) { line in
                                    TerminalLineView(line: line, fontSize: settingsManager.fontSize)
                                        .id(line.id)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                        .frame(maxHeight: .infinity)
                        .background(Color.black)
                        .onChange(of: terminalSession.outputLines.count) { _, _ in
                            if let lastLine = terminalSession.outputLines.last {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    proxy.scrollTo(lastLine.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                Divider().background(Color.green.opacity(0.5))

                HStack(spacing: 8) {
                    Button {
                        showingQuickCommands = true
                    } label: {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.green)
                            .frame(width: 32, height: 32)
                    }

                    commandInputField

                    Button {
                        sendCommand()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(inputText.isEmpty ? .gray : .green)
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.95))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("Terminal")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    ConnectionStatusBadge()
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Clear Screen") { terminalSession.clear() }
                        Button("List Sessions") { terminalSession.listSessions() }
                        Button("Reconnect") {
                            Task { await connectionManager.reconnect() }
                        }
                        Divider()
                        Button("Send Ctrl+C", role: .destructive) {
                            terminalSession.sendControlC()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingQuickCommands) {
                QuickCommandsSheet(onSelect: { command in
                    inputText = command
                    showingQuickCommands = false
                    sendCommand()
                })
            }
            .onAppear {
                terminalSession.connectionManager = connectionManager
                if connectionManager.isConnected {
                    terminalSession.startSession()
                }
            }
            .onChange(of: connectionManager.connectionState) { _, newState in
                if case .connected = newState {
                    terminalSession.startSession()
                }
            }
        }
    }

    @ViewBuilder
    private var commandInputField: some View {
        #if os(iOS)
        TextField("Enter command...", text: $inputText)
            .textFieldStyle(.plain)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.green)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($isInputFocused)
            .onSubmit { sendCommand() }
        #else
        TextField("Enter command...", text: $inputText)
            .textFieldStyle(.plain)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.green)
            .focused($isInputFocused)
            .onSubmit { sendCommand() }
        #endif
    }

    private func sendCommand() {
        guard !inputText.isEmpty else { return }
        terminalSession.send(command: inputText)
        inputText = ""
    }
}

/// Renders a single terminal line with full ANSI color support.
/// Output lines are parsed through ANSIParser for multi-color spans.
/// Input/system/error lines use their fixed type colors.
struct TerminalLineView: View {
    let line: TerminalLine
    let fontSize: Double

    var body: some View {
        Text(renderedText)
            .font(.system(size: CGFloat(fontSize), design: .monospaced))
            .textSelection(.enabled)
            .lineLimit(nil)
    }

    private var renderedText: AttributedString {
        switch line.type {
        case .output:
            // Full ANSI parsing for server output
            return ANSIParser.parse(line.text, defaultColor: .white)
        case .input:
            return ANSIParser.parse(line.text, defaultColor: .green)
        case .error:
            var s = AttributedString(line.text)
            s.foregroundColor = .red
            return s
        case .system:
            var s = AttributedString(line.text)
            s.foregroundColor = .yellow
            return s
        }
    }
}

struct ConnectionStatusBadge: View {
    @EnvironmentObject var connectionManager: ConnectionManager

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var statusColor: Color {
        switch connectionManager.connectionState {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .red
        case .error: return .red
        }
    }

    private var statusText: String {
        switch connectionManager.connectionState {
        case .connected: return connectionManager.currentHost?.name ?? "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

struct WelcomeView: View {
    let connectionManager: ConnectionManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
            Image(systemName: "terminal")
                .font(.system(size: 48))
                .foregroundColor(.green.opacity(0.8))

            VStack(spacing: 8) {
                Text("GhosttlyTermLinkkY")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Remote terminal via Tailscale")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if connectionManager.hosts.isEmpty {
                VStack(spacing: 12) {
                    Text("No hosts configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Tap \"Hosts\" to add your server")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else {
                VStack(spacing: 12) {
                    Button {
                        Task { await connectionManager.connect(to: connectionManager.hosts[0]) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                            Text("Connect to \(connectionManager.hosts[0].name)")
                        }
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(12)
                    }

                    Text("or tap \"Hosts\" to manage servers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .background(Color.black)
    }
}

struct QuickCommandsSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss

    let commands = [
        ("Claude Code", "claude"),
        ("List Files", "ls -la"),
        ("Git Status", "git status"),
        ("Git Log", "git log --oneline -10"),
        ("Git Pull", "git pull"),
        ("NPM Install", "npm install"),
        ("NPM Run Dev", "npm run dev"),
        ("Python", "python3"),
        ("Tmux Sessions", "tmux list-sessions"),
        ("Clear", "clear"),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(commands, id: \.0) { name, command in
                    Button {
                        onSelect(command)
                    } label: {
                        HStack {
                            Text(name).foregroundColor(.primary)
                            Spacer()
                            Text(command)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Quick Commands")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
}
