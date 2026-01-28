//
//  TerminalSession.swift
//  GhosttlyTermLinkkY
//
//  Manages terminal I/O over the WebSocket connection.
//  Receives streaming output, handles command history.
//

import Foundation
import SwiftUI

@MainActor
class TerminalSession: ObservableObject {
    @Published var outputLines: [TerminalLine] = []
    @Published var isRunning = false

    weak var connectionManager: ConnectionManager?

    private let maxLines = 2000
    private var historyIndex: Int = -1
    private var commandHistory: [String] = []
    private var currentBuffer: String = ""

    init() {
        outputLines.append(.system("GhosttlyTermLinkkY v1.1"))
        outputLines.append(.system("Connect to a host to begin"))
    }

    func startSession(tmuxSession: String? = nil) {
        guard let manager = connectionManager,
              let sshService = manager.sshService else {
            outputLines.append(.error("No connection available"))
            return
        }

        sshService.onOutput { [weak self] data in
            Task { @MainActor in
                self?.handleOutput(data)
            }
        }

        sshService.onExit { [weak self] code in
            Task { @MainActor in
                self?.outputLines.append(.system("Session exited (code: \(code ?? -1))"))
                self?.isRunning = false
            }
        }

        isRunning = true

        if let tmux = tmuxSession {
            outputLines.append(.system("Attaching to tmux session: \(tmux)"))
        } else {
            outputLines.append(.system("Session started"))
        }

        if let host = manager.currentHost {
            outputLines.append(.system("Connected to \(host.name) (\(host.hostname))"))
        }
    }

    private func handleOutput(_ data: String) {
        currentBuffer += data

        let parts = currentBuffer.split(separator: "\n", omittingEmptySubsequences: false)

        if parts.count > 1 {
            for i in 0..<(parts.count - 1) {
                let line = String(parts[i])
                outputLines.append(.output(line))
            }
            currentBuffer = String(parts.last ?? "")
        }

        trimLinesIfNeeded()
    }

    func flushBuffer() {
        if !currentBuffer.isEmpty {
            outputLines.append(.output(currentBuffer))
            currentBuffer = ""
        }
    }

    func send(command: String) {
        guard !command.isEmpty else { return }

        commandHistory.append(command)
        historyIndex = commandHistory.count

        flushBuffer()
        outputLines.append(.input(command))

        guard let manager = connectionManager,
              manager.isConnected,
              let sshService = manager.sshService else {
            outputLines.append(.error("Not connected to any host"))
            return
        }

        if handleLocalCommand(command) { return }

        sshService.sendInput(command + "\n")
    }

    func sendControlC() {
        flushBuffer()
        outputLines.append(.system("^C"))
        connectionManager?.sshService?.sendInterrupt()
        isRunning = false
    }

    func clear() {
        outputLines.removeAll()
        currentBuffer = ""
        outputLines.append(.system("Screen cleared"))
    }

    func previousCommand() -> String? {
        guard !commandHistory.isEmpty else { return nil }
        historyIndex = max(0, historyIndex - 1)
        return commandHistory[historyIndex]
    }

    func nextCommand() -> String? {
        guard !commandHistory.isEmpty else { return nil }
        historyIndex = min(commandHistory.count - 1, historyIndex + 1)
        return commandHistory[historyIndex]
    }

    func listSessions() {
        connectionManager?.sshService?.sendCommand("sessions")
    }

    private func handleLocalCommand(_ command: String) -> Bool {
        let cmd = command.trimmingCharacters(in: .whitespaces).lowercased()

        switch cmd {
        case "clear":
            clear()
            return true
        case "exit", "quit":
            connectionManager?.disconnect()
            outputLines.append(.system("Disconnected"))
            isRunning = false
            return true
        case "history":
            outputLines.append(.output("Command History:"))
            for (i, cmd) in commandHistory.enumerated() {
                outputLines.append(.output("  \(i + 1)  \(cmd)"))
            }
            return true
        case "sessions":
            listSessions()
            return true
        default:
            return false
        }
    }

    private func trimLinesIfNeeded() {
        if outputLines.count > maxLines {
            outputLines.removeFirst(outputLines.count - maxLines)
        }
    }
}
