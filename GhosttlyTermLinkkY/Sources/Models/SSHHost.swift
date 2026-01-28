//
//  SSHHost.swift
//  GhosttlyTermLinkkY
//

import Foundation

struct SSHHost: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var hostname: String
    var port: Int
    var username: String
    var password: String?
    var useKeyAuth: Bool
    var privateKeyPath: String?
    var createdAt: Date
    var lastConnected: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        hostname: String,
        port: Int = 22,
        username: String,
        password: String? = nil,
        useKeyAuth: Bool = false,
        privateKeyPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.useKeyAuth = useKeyAuth
        self.privateKeyPath = privateKeyPath
        self.createdAt = Date()
    }
    
    var connectionString: String {
        "\(username)@\(hostname):\(port)"
    }
}

// Default hosts for quick setup
extension SSHHost {
    static let presets: [SSHHost] = [
        // Add common dev machine setups here
    ]
}
