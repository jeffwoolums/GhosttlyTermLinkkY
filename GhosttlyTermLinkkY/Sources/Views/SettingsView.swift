//
//  SettingsView.swift
//  GhosttlyTermLinkkY
//
//  Settings - NO NavigationStack wrapper, clean layout.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var showingQuickCommands = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Settings list
                List {
                    // Terminal
                    Section("Terminal") {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(settingsManager.fontSize)) pt")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $settingsManager.fontSize, in: 10...24, step: 1)
                            .tint(.green)
                    }
                    
                    // Quick Commands
                    Section {
                        Button {
                            showingQuickCommands = true
                        } label: {
                            HStack {
                                Label("Quick Commands", systemImage: "bolt.fill")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(settingsManager.quickCommands.count)")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    
                    // Connection
                    Section("Connection") {
                        HStack {
                            Text("Status")
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 8, height: 8)
                                Text(statusText)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if connectionManager.isConnected {
                            Button("Disconnect", role: .destructive) {
                                connectionManager.disconnect()
                            }
                        }
                    }
                    
                    // About
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.1.0")
                                .foregroundColor(.secondary)
                        }
                        
                        Link(destination: URL(string: "https://github.com/jeffwoolums/GhosttlyTermLinkkY")!) {
                            HStack {
                                Text("GitHub")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(isPresented: $showingQuickCommands) {
            QuickCommandsSettingsView()
        }
    }
    
    private var statusColor: Color {
        switch connectionManager.connectionState {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected, .error: return .red
        }
    }
    
    private var statusText: String {
        switch connectionManager.connectionState {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }
}
