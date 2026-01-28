//
//  SettingsManager.swift
//  GhosttlyTermLinkkY
//

import Foundation
import SwiftUI

@MainActor
class SettingsManager: ObservableObject {
    // Terminal settings
    @AppStorage("fontSize") var fontSize: Double = 14
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true
    @AppStorage("keepScreenOn") var keepScreenOn: Bool = true
    
    // Connection settings
    @AppStorage("connectionTimeout") var connectionTimeout: Int = 30
    @AppStorage("autoReconnect") var autoReconnect: Bool = true
    @AppStorage("vibrateOnDisconnect") var vibrateOnDisconnect: Bool = true
    
    // Quick commands
    @Published var quickCommands: [QuickCommand] = []
    
    private let quickCommandsKey = "quick_commands"
    
    init() {
        loadQuickCommands()
    }
    
    // MARK: - Quick Commands
    
    func loadQuickCommands() {
        if let data = UserDefaults.standard.data(forKey: quickCommandsKey),
           let decoded = try? JSONDecoder().decode([QuickCommand].self, from: data) {
            quickCommands = decoded
        } else {
            // Load defaults on first run
            quickCommands = QuickCommand.defaults
            saveQuickCommands()
        }
    }
    
    func saveQuickCommands() {
        if let encoded = try? JSONEncoder().encode(quickCommands) {
            UserDefaults.standard.set(encoded, forKey: quickCommandsKey)
        }
    }
    
    func addQuickCommand(_ command: QuickCommand) {
        quickCommands.append(command)
        saveQuickCommands()
    }
    
    func removeQuickCommand(_ command: QuickCommand) {
        quickCommands.removeAll { $0.id == command.id }
        saveQuickCommands()
    }
    
    func updateQuickCommand(_ command: QuickCommand) {
        if let index = quickCommands.firstIndex(where: { $0.id == command.id }) {
            quickCommands[index] = command
            saveQuickCommands()
        }
    }
    
    func moveQuickCommand(from source: IndexSet, to destination: Int) {
        quickCommands.move(fromOffsets: source, toOffset: destination)
        saveQuickCommands()
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        fontSize = 14
        hapticFeedback = true
        keepScreenOn = true
        connectionTimeout = 30
        autoReconnect = true
        vibrateOnDisconnect = true
        quickCommands = QuickCommand.defaults
        saveQuickCommands()
    }
}
