//
//  SSHService.swift
//  GhosttlyTermLinkkY
//
//  Pure Swift SSH implementation using Network framework
//  For production, consider using a library like NMSSH or Citadel
//

import Foundation
import Network

enum SSHError: Error, LocalizedError {
    case connectionFailed(String)
    case authenticationFailed
    case timeout
    case notConnected
    case commandFailed(String)
    case channelError
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .authenticationFailed: return "Authentication failed"
        case .timeout: return "Connection timed out"
        case .notConnected: return "Not connected"
        case .commandFailed(let msg): return "Command failed: \(msg)"
        case .channelError: return "Channel error"
        }
    }
}

/// SSH Service using Network framework
/// Note: This is a simplified implementation. For full SSH support,
/// integrate a library like NMSSH (via Swift Package) or Citadel (pure Swift SSH2)
@MainActor
class SSHService: ObservableObject {
    let host: SSHHost
    
    @Published var isConnected = false
    @Published var lastOutput: String = ""
    
    private var connection: NWConnection?
    private var outputCallback: ((String) -> Void)?
    private var webSocketTask: URLSessionWebSocketTask?
    
    init(host: SSHHost) {
        self.host = host
    }
    
    /// Connect to the SSH host
    func connect() async throws {
        // For now, we'll use TCP connection check
        // Full SSH would require integrating Citadel or NMSSH
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host.hostname),
            port: NWEndpoint.Port(integerLiteral: UInt16(host.port))
        )
        
        let connection = NWConnection(to: endpoint, using: .tcp)
        self.connection = connection
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var resumed = false
            
            connection.stateUpdateHandler = { [weak self] state in
                guard !resumed else { return }
                
                switch state {
                case .ready:
                    resumed = true
                    Task { @MainActor in
                        self?.isConnected = true
                    }
                    continuation.resume()
                case .failed(let error):
                    resumed = true
                    continuation.resume(throwing: SSHError.connectionFailed(error.localizedDescription))
                case .cancelled:
                    resumed = true
                    continuation.resume(throwing: SSHError.connectionFailed("Cancelled"))
                default:
                    break
                }
            }
            
            connection.start(queue: .main)
            
            // Timeout
            Task {
                try await Task.sleep(for: .seconds(10))
                if !resumed {
                    resumed = true
                    connection.cancel()
                    continuation.resume(throwing: SSHError.timeout)
                }
            }
        }
    }
    
    /// Disconnect from the host
    func disconnect() {
        connection?.cancel()
        connection = nil
        webSocketTask?.cancel()
        webSocketTask = nil
        isConnected = false
    }
    
    /// Execute a command and return output
    func execute(command: String) async throws -> String {
        guard isConnected else {
            throw SSHError.notConnected
        }
        
        // Simulated response for UI testing
        // In production, replace with actual SSH command execution
        try await Task.sleep(for: .milliseconds(100))
        return simulatedOutput(for: command)
    }
    
    /// Set callback for streaming output
    func onOutput(_ callback: @escaping (String) -> Void) {
        self.outputCallback = callback
    }
    
    /// Send Ctrl+C signal
    func sendInterrupt() async throws {
        guard isConnected else { throw SSHError.notConnected }
        outputCallback?("^C")
    }
    
    /// Simulated command output for UI testing
    private func simulatedOutput(for command: String) -> String {
        let cmd = command.trimmingCharacters(in: .whitespaces).lowercased()
        
        switch cmd {
        case "ls", "ls -la":
            return """
            total 48
            drwxr-xr-x  12 \(host.username)  staff   384 Jan 27 10:00 .
            drwxr-xr-x   5 \(host.username)  staff   160 Jan 27 09:00 ..
            -rw-r--r--   1 \(host.username)  staff   256 Jan 27 10:00 .gitignore
            drwxr-xr-x   8 \(host.username)  staff   256 Jan 27 10:00 .git
            -rw-r--r--   1 \(host.username)  staff  1024 Jan 27 10:00 README.md
            -rw-r--r--   1 \(host.username)  staff  2048 Jan 27 10:00 package.json
            drwxr-xr-x  10 \(host.username)  staff   320 Jan 27 10:00 src
            """
        case "pwd":
            return "/Users/\(host.username)/developer"
        case "whoami":
            return host.username
        case "git status":
            return """
            On branch main
            Your branch is up to date with 'origin/main'.
            
            nothing to commit, working tree clean
            """
        case "claude":
            return """
            ╭─────────────────────────────────────────────╮
            │ Claude Code                                 │
            │ Anthropic's AI coding assistant             │
            ╰─────────────────────────────────────────────╯
            
            Type your prompt or /help for commands...
            """
        case "clear":
            return ""
        case let c where c.starts(with: "echo "):
            return String(command.dropFirst(5))
        case "date":
            return Date().formatted()
        case "uptime":
            return " 10:00  up 7 days, 12:34, 2 users, load averages: 1.23 1.45 1.67"
        default:
            return "bash: \(command): command simulated"
        }
    }
}
