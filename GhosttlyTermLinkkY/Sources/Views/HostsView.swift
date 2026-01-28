//
//  HostsView.swift
//  GhosttlyTermLinkkY
//
//  Host list - NO NavigationStack wrapper, clean layout.
//

import SwiftUI

struct HostsView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var showingAddHost = false
    @State private var editingHost: SSHHost?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Hosts")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        showingAddHost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // List
                List {
                    if !connectionManager.hosts.isEmpty {
                        Section {
                            ForEach(connectionManager.hosts) { host in
                                HostRow(host: host)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        Task {
                                            await connectionManager.connect(to: host)
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            connectionManager.removeHost(host)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            editingHost = host
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                            }
                        } header: {
                            Text("Saved Hosts")
                        }
                    }
                    
                    Section {
                        Button {
                            showingAddHost = true
                        } label: {
                            Label("Add New Host", systemImage: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    } footer: {
                        Text("Use Tailscale IP (100.x.x.x) for remote access.")
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(isPresented: $showingAddHost) {
            AddHostSheet()
        }
        .sheet(item: $editingHost) { host in
            EditHostSheet(host: host)
        }
    }
}

// MARK: - Host Row

struct HostRow: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    let host: SSHHost
    
    private var isConnected: Bool {
        connectionManager.currentHost?.id == host.id && connectionManager.isConnected
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isConnected ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(host.name)
                    .font(.headline)
                Text("\(host.username)@\(host.hostname):\(host.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontDesign(.monospaced)
            }
            
            Spacer()
            
            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Host

struct AddHostSheet: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var hostname = ""
    @State private var port = "3847"
    @State private var username = "clawdbot"
    @State private var password = ""

    private var isValid: Bool {
        !name.isEmpty && !hostname.isEmpty && !username.isEmpty && Int(port) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Host Details") {
                    TextField("Display Name", text: $name)
                    
                    TextField("Hostname / IP", text: $hostname)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                    
                    TextField("Port", text: $port)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                
                Section("Authentication") {
                    TextField("Username", text: $username)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    
                    SecureField("Auth Token", text: $password)
                }
                
                Section {
                    Text("Default port 3847 is for TermLinky server.\nUse Tailscale IP for remote connections.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveHost() }
                        .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveHost() {
        let host = SSHHost(
            name: name,
            hostname: hostname,
            port: Int(port) ?? 3847,
            username: username,
            password: password.isEmpty ? nil : password,
            useKeyAuth: false
        )
        connectionManager.addHost(host)
        dismiss()
    }
}

// MARK: - Edit Host

struct EditHostSheet: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @Environment(\.dismiss) var dismiss
    let host: SSHHost
    
    @State private var name = ""
    @State private var hostname = ""
    @State private var port = ""
    @State private var username = ""
    @State private var password = ""

    private var isValid: Bool {
        !name.isEmpty && !hostname.isEmpty && !username.isEmpty && Int(port) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Host Details") {
                    TextField("Display Name", text: $name)
                    
                    TextField("Hostname / IP", text: $hostname)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    
                    TextField("Port", text: $port)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                
                Section("Authentication") {
                    TextField("Username", text: $username)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    
                    SecureField("Auth Token", text: $password)
                }
            }
            .navigationTitle("Edit Host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { updateHost() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                name = host.name
                hostname = host.hostname
                port = String(host.port)
                username = host.username
                password = host.password ?? ""
            }
        }
    }
    
    private func updateHost() {
        var updated = host
        updated.name = name
        updated.hostname = hostname
        updated.port = Int(port) ?? 3847
        updated.username = username
        updated.password = password.isEmpty ? nil : password
        connectionManager.updateHost(updated)
        dismiss()
    }
}
