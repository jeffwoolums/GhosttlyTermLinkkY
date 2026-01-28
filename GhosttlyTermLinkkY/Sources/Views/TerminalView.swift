//
//  TerminalView.swift
//  GhosttlyTermLinkkY
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
                // Terminal output area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(terminalSession.outputLines) { line in
                                TerminalLineView(line: line, fontSize: settingsManager.fontSize)
                                    .id(line.id)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .background(Color.black)
                    .onChange(of: terminalSession.outputLines.count) { _, _ in
                        if let lastLine = terminalSession.outputLines.last {
                            withAnimation(.easeOut(duration: 0.1)) {
                                proxy.scrollTo(lastLine.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                    .background(Color.green.opacity(0.5))
                
                // Input area
                HStack(spacing: 8) {
                    // Quick commands button
                    Button {
                        showingQuickCommands = true
                    } label: {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.green)
                            .frame(width: 32, height: 32)
                    }
                    
                    // Command input
                    TextField("Enter command...", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isInputFocused)
                        .onSubmit {
                            sendCommand()
                        }
                    
                    // Send button
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
            .background(Color.black)
            .navigationTitle("Terminal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ConnectionStatusBadge()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear Screen") {
                            terminalSession.clear()
                        }
                        Button("Reconnect") {
                            Task {
                                await connectionManager.reconnect()
                            }
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
        }
    }
    
    private func sendCommand() {
        guard !inputText.isEmpty else { return }
        terminalSession.send(command: inputText)
        inputText = ""
    }
}

struct TerminalLineView: View {
    let line: TerminalLine
    let fontSize: CGFloat
    
    var body: some View {
        Text(attributedString)
            .font(.system(size: fontSize, design: .monospaced))
            .textSelection(.enabled)
    }
    
    private var attributedString: AttributedString {
        var attributed = AttributedString(line.text)
        attributed.foregroundColor = line.color
        return attributed
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

struct QuickCommandsSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    let commands = [
        ("Claude Code", "claude"),
        ("List Files", "ls -la"),
        ("Git Status", "git status"),
        ("Git Pull", "git pull"),
        ("Git Log", "git log --oneline -10"),
        ("NPM Install", "npm install"),
        ("NPM Run Dev", "npm run dev"),
        ("Python", "python3"),
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
                            Text(name)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(command)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Quick Commands")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    TerminalView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsManager())
}
