//
//  TerminalView.swift
//  GhosttlyTermLinkkY
//
//  Full-screen terminal - NO NavigationStack, edge-to-edge black.
//

import SwiftUI

struct TerminalView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var terminalSession = TerminalSession()
    @State private var inputText: String = ""
    @State private var showingQuickCommands = false
    @State private var showingMenu = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Full-bleed black
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerBar
                    .padding(.top, 8)
                
                // Terminal content
                if !connectionManager.isConnected && terminalSession.outputLines.count <= 2 {
                    welcomeContent
                } else {
                    terminalContent
                }
                
                // Input bar
                inputBar
            }
        }
        .confirmationDialog("Terminal", isPresented: $showingMenu) {
            Button("Clear Screen") { terminalSession.clear() }
            Button("List Sessions") { terminalSession.listSessions() }
            Button("Reconnect") {
                Task { await connectionManager.reconnect() }
            }
            Button("Send Ctrl+C", role: .destructive) {
                terminalSession.sendControlC()
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingQuickCommands) {
            QuickCommandsSheet { command in
                inputText = command
                showingQuickCommands = false
                sendCommand()
            }
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
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack {
            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Terminal")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                showingMenu = true
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Welcome
    
    private var welcomeContent: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "terminal")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("GhosttlyTermLinkkY")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Remote terminal for Claude Code")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if connectionManager.hosts.isEmpty {
                Text("Go to Hosts tab to add a server")
                    .font(.callout)
                    .foregroundColor(.green)
            } else {
                Button {
                    Task { await connectionManager.connect(to: connectionManager.hosts[0]) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Connect to \(connectionManager.hosts[0].name)")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Terminal Output
    
    private var terminalContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(terminalSession.outputLines) { line in
                        TerminalLineView(line: line, fontSize: settingsManager.fontSize)
                            .id(line.id)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .onChange(of: terminalSession.outputLines.count) { _, _ in
                if let last = terminalSession.outputLines.last {
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {
                showingQuickCommands = true
            } label: {
                Image(systemName: "bolt.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                    .frame(width: 36, height: 36)
            }
            
            TextField("Enter command...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .focused($isInputFocused)
                .onSubmit { sendCommand() }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
            
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
        .padding(.vertical, 10)
        .padding(.bottom, 4)
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch connectionManager.connectionState {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected, .error: return .red
        }
    }
    
    private var statusText: String {
        switch connectionManager.connectionState {
        case .connected: return connectionManager.currentHost?.name ?? "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error(let msg): return msg
        }
    }
    
    private func sendCommand() {
        guard !inputText.isEmpty else { return }
        terminalSession.send(command: inputText)
        inputText = ""
    }
}

// MARK: - Terminal Line

struct TerminalLineView: View {
    let line: TerminalLine
    let fontSize: Double

    var body: some View {
        Text(renderedText)
            .font(.system(size: CGFloat(fontSize), design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var renderedText: AttributedString {
        switch line.type {
        case .output:
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

// MARK: - Quick Commands

struct QuickCommandsSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        NavigationStack {
            List {
                ForEach(settingsManager.quickCommands) { cmd in
                    Button {
                        onSelect(cmd.command)
                    } label: {
                        HStack {
                            Text(cmd.name)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(cmd.command)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                if settingsManager.quickCommands.isEmpty {
                    Text("No quick commands.\nAdd them in Settings.")
                        .foregroundColor(.secondary)
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
