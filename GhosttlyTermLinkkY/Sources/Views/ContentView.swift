//
//  ContentView.swift
//  GhosttlyTermLinkkY
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var selectedTab: Tab = .terminal
    
    enum Tab {
        case terminal
        case hosts
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TerminalView()
                .tabItem {
                    Image(systemName: "terminal.fill")
                    Text("Terminal")
                }
                .tag(Tab.terminal)

            HostsView()
                .tabItem {
                    Image(systemName: "server.rack")
                    Text("Hosts")
                }
                .tag(Tab.hosts)

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(Tab.settings)
        }
        .tint(.green)
    }
}

#if DEBUG && canImport(PreviewsMacros)
#Preview {
    ContentView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsManager())
}
#endif
