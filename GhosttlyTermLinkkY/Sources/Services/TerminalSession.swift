//
//  TerminalSession.swift
//  GhosttlyTermLinkkY
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TerminalSession: ObservableObject {
    @Published var outputLines: [TerminalLine] = []
    @Published var isRunning = false
    
    weak var connectionManager: ConnectionManager?
    
    private let maxLines = 1000
    private var historyIndex: Int = -1
    private var commandHistory: [String] = []
    
    init() {
        outputLines.append(.system("GhosttlyTermLinkkY v1.0"))
        outputLines.append(.system("Connect to a host to begin"))
    }
    
    func startSession() {
        outputLines.append(.system("Session started"))
        
        if let host = connectionManager?.currentHost {
            outputLines.append(.system("Connected to \(host.name)"))
            outputLines.append(.output("Welcome to \(host.hostname)"))
            outputLines.append(.output(""))
        }
    }
    
    func send(command: String) {
        guard !command.isEmpty else { return }
        
        // Add to history
        commandHistory.append(command)
        historyIndex = commandHistory.count
        
        // Display input
        outputLines.append(.input(command))
        
        // Check if connected
        guard let manager = connectionManager,
              manager.isConnected,
              let sshService = manager.sshService else {
            outputLines.append(.error("Not connected to any host"))
            return
        }
        
        // Handle local commands
        if handleLocalCommand(command) {
            return
        }
        
        // Execute remote command
        isRunning = true
        
        Task {
            do {
                let output = try await sshService.execute(command: command)
                
                // Split output into lines
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    outputLines.append(.output(line))
                }
            } catch {
                outputLines.append(.error(error.localizedDescription))
            }
            
            isRunning = false
            trimLinesIfNeeded()
        }
    }
    
    func sendControlC() {
        outputLines.append(.system("^C"))
        
        Task {
            try? await connectionManager?.sshService?.sendInterrupt()
        }
        
        isRunning = false
    }
    
    func clear() {
        outputLines.removeAll()
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
    
    private func handleLocalCommand(_ command: String) -> Bool {
        let cmd = command.trimmingCharacters(in: .whitespaces).lowercased()
        
        switch cmd {
        case "clear":
            clear()
            return true
        case "exit", "quit":
            connectionManager?.disconnect()
            outputLines.append(.system("Disconnected"))
            return true
        case "history":
            outputLines.append(.output("Command History:"))
            for (i, cmd) in commandHistory.enumerated() {
                outputLines.append(.output("  \(i + 1)  \(cmd)"))
            }
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
