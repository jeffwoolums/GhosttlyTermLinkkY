//
//  ConnectionManager.swift
//  GhosttlyTermLinkkY
//

import Foundation
import SwiftUI
import Combine

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

@MainActor
class ConnectionManager: ObservableObject {
    @Published var hosts: [SSHHost] = []
    @Published var currentHost: SSHHost?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var sshService: SSHService?
    
    private let hostsKey = "saved_hosts"
    
    var isConnected: Bool {
        connectionState == .connected
    }
    
    init() {
        loadHosts()
    }
    
    // MARK: - Host Management
    
    func addHost(_ host: SSHHost) {
        hosts.append(host)
        saveHosts()
    }
    
    func removeHost(_ host: SSHHost) {
        hosts.removeAll { $0.id == host.id }
        if currentHost?.id == host.id {
            disconnect()
        }
        saveHosts()
    }
    
    func updateHost(_ host: SSHHost) {
        if let index = hosts.firstIndex(where: { $0.id == host.id }) {
            hosts[index] = host
            saveHosts()
        }
    }
    
    private func loadHosts() {
        guard let data = UserDefaults.standard.data(forKey: hostsKey),
              let decoded = try? JSONDecoder().decode([SSHHost].self, from: data) else {
            return
        }
        hosts = decoded
    }
    
    private func saveHosts() {
        guard let encoded = try? JSONEncoder().encode(hosts) else { return }
        UserDefaults.standard.set(encoded, forKey: hostsKey)
    }
    
    // MARK: - Connection
    
    func connect(to host: SSHHost) async {
        guard connectionState != .connecting else { return }
        
        connectionState = .connecting
        currentHost = host
        
        let service = SSHService(host: host)
        
        do {
            try await service.connect()
            sshService = service
            connectionState = .connected
            
            // Update last connected time
            var updatedHost = host
            updatedHost.lastConnected = Date()
            updateHost(updatedHost)
        } catch {
            connectionState = .error(error.localizedDescription)
            currentHost = nil
        }
    }
    
    func disconnect() {
        sshService?.disconnect()
        sshService = nil
        currentHost = nil
        connectionState = .disconnected
    }
    
    func reconnect() async {
        guard let host = currentHost else { return }
        disconnect()
        await connect(to: host)
    }
}
