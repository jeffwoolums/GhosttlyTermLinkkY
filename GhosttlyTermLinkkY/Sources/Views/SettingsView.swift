//
//  SettingsView.swift
//  GhosttlyTermLinkkY
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var connectionManager: ConnectionManager
    
    var body: some View {
        NavigationStack {
            List {
                Section("Terminal") {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Stepper("\(Int(settingsManager.fontSize))", value: $settingsManager.fontSize, in: 10...24)
                            .fixedSize()
                    }
                    
                    Toggle("Haptic Feedback", isOn: $settingsManager.hapticFeedback)
                    
                    Toggle("Keep Screen On", isOn: $settingsManager.keepScreenOn)
                }
                
                Section("Connection") {
                    HStack {
                        Text("Timeout")
                        Spacer()
                        Picker("", selection: $settingsManager.connectionTimeout) {
                            Text("10s").tag(10)
                            Text("30s").tag(30)
                            Text("60s").tag(60)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                    
                    Toggle("Auto-Reconnect", isOn: $settingsManager.autoReconnect)
                    
                    Toggle("Vibrate on Disconnect", isOn: $settingsManager.vibrateOnDisconnect)
                }
                
                Section("Quick Commands") {
                    NavigationLink {
                        QuickCommandsSettingsView()
                    } label: {
                        Label("Manage Commands", systemImage: "bolt.fill")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/jeffwoolums/GhosttlyTermLinkkY")!) {
                        HStack {
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://tailscale.com")!) {
                        HStack {
                            Text("Tailscale")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        settingsManager.resetToDefaults()
                    } label: {
                        Text("Reset to Defaults")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}