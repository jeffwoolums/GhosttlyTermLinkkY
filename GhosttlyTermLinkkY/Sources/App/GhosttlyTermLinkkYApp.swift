//
//  GhosttlyTermLinkkYApp.swift
//  GhosttlyTermLinkkY
//
//  Ghostly remote app for Claude Code terminal access
//  iOS to Mac dev rig via Tailscale
//

import SwiftUI

@main
struct GhosttlyTermLinkkYApp: App {
    @StateObject private var connectionManager = ConnectionManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
                .environmentObject(settingsManager)
                .preferredColorScheme(.dark)
        }
    }
}
