//
//  SSHService.swift
//  GhosttlyTermLinkkY
//
//  WebSocket client connecting to the GhosttlyTermLinkkY Node server.
//  Auth flow: POST /auth -> JWT -> WebSocket /terminal -> stream I/O
//

import Foundation

enum SSHError: Error, LocalizedError {
    case connectionFailed(String)
    case authenticationFailed(String)
    case timeout
    case notConnected
    case sessionLimitReached

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .authenticationFailed(let msg): return "Auth failed: \(msg)"
        case .timeout: return "Connection timed out"
        case .notConnected: return "Not connected"
        case .sessionLimitReached: return "Server session limit reached"
        }
    }
}

@MainActor
class SSHService: ObservableObject {
    let host: SSHHost

    @Published var isConnected = false
    @Published var lastOutput: String = ""

    private var sessionToken: String?
    private var webSocketTask: URLSessionWebSocketTask?
    private var outputCallback: ((String) -> Void)?
    private var exitCallback: ((Int?) -> Void)?
    private var isListening = false

    init(host: SSHHost) {
        self.host = host
    }

    func connect(tmuxSession: String? = nil) async throws {
        let sessionToken = try await authenticate()
        self.sessionToken = sessionToken

        let wsURL = URL(string: "ws://\(host.hostname):\(host.port)/terminal")!
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: wsURL)
        task.resume()
        self.webSocketTask = task

        var authMsg: [String: Any] = [
            "type": "auth",
            "token": sessionToken,
            "cols": 120,
            "rows": 40,
        ]
        if let tmux = tmuxSession {
            authMsg["tmuxSession"] = tmux
        }
        try await task.send(.string(serialize(authMsg)))

        let response = try await task.receive()
        guard case .string(let data) = response else {
            throw SSHError.connectionFailed("Expected string message")
        }

        let parsed = deserialize(data)
        guard parsed["type"] as? String == "auth_success" else {
            let msg = parsed["message"] as? String ?? "Unknown auth error"
            throw SSHError.authenticationFailed(msg)
        }

        isConnected = true
        startListening()
    }

    func disconnect() {
        isListening = false
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        sessionToken = nil
        isConnected = false
    }

    func sendInput(_ text: String) {
        guard let task = webSocketTask else { return }
        let msg = serialize(["type": "input", "data": text])
        Task { try? await task.send(.string(msg)) }
    }

    func sendCommand(_ command: String) {
        guard let task = webSocketTask else { return }
        let msg = serialize(["type": "command", "command": command])
        Task { try? await task.send(.string(msg)) }
    }

    func resize(cols: Int, rows: Int) {
        guard let task = webSocketTask else { return }
        let msg = serialize(["type": "resize", "cols": cols, "rows": rows])
        Task { try? await task.send(.string(msg)) }
    }

    func sendInterrupt() {
        sendCommand("interrupt")
    }

    func onOutput(_ callback: @escaping (String) -> Void) {
        self.outputCallback = callback
    }

    func onExit(_ callback: @escaping (Int?) -> Void) {
        self.exitCallback = callback
    }

    private func authenticate() async throws -> String {
        let authURL = URL(string: "http://\(host.hostname):\(host.port)/auth")!
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.httpBody = serialize(["token": host.password ?? ""])
            .data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SSHError.connectionFailed("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SSHError.authenticationFailed("HTTP \(httpResponse.statusCode): \(body)")
        }

        let json = deserialize(String(data: data, encoding: .utf8) ?? "")
        guard let token = json["sessionToken"] as? String else {
            throw SSHError.authenticationFailed("No session token in response")
        }
        return token
    }

    private func startListening() {
        isListening = true
        Task { [weak self] in
            guard let self = self else { return }
            while self.isListening {
                do {
                    let message = try await self.webSocketTask?.receive()
                    guard let message = message else { break }

                    switch message {
                    case .string(let text):
                        let parsed = self.deserialize(text)
                        self.handleMessage(parsed)
                    case .data:
                        break
                    @unknown default:
                        break
                    }
                } catch {
                    await MainActor.run {
                        self.isConnected = false
                        self.outputCallback?("[Connection lost: \(error.localizedDescription)]")
                    }
                    break
                }
            }
        }
    }

    @MainActor
    private func handleMessage(_ msg: [String: Any]) {
        let type = msg["type"] as? String ?? ""

        switch type {
        case "output":
            let data = msg["data"] as? String ?? ""
            lastOutput = data
            outputCallback?(data)

        case "exit":
            let code = msg["exitCode"] as? Int
            exitCallback?(code)
            isConnected = false

        case "error":
            let errMsg = msg["message"] as? String ?? "Unknown error"
            outputCallback?("[Error: \(errMsg)]")

        case "sessions":
            if let sessions = msg["data"] as? [[String: Any]] {
                let names = sessions.compactMap { $0["name"] as? String }
                outputCallback?("[Sessions: \(names.joined(separator: ", "))]")
            }

        default:
            break
        }
    }

    private func serialize(_ dict: [String: Any]) -> String {
        (try? JSONSerialization.data(withJSONObject: dict, options: []))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }

    private func deserialize(_ string: String) -> [String: Any] {
        guard let data = string.data(using: .utf8) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}
