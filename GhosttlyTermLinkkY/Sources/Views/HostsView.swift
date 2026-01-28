//
//  HostsView.swift
//  GhosttlyTermLinkkY
//

import SwiftUI

struct HostsView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var showingAddHost = false
    @State private var editingHost: SSHHost?

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
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
            .padding()
            .background(Color.black)

            // Host list
            List {
                Section {
                    ForEach(connectionManager.hosts) { host in
                        HostRowView(host: host)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task {
                                    await connectionManager.connect(to: host)
                                }
                            }
                            .swipeActions(edge: .trailing) {
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
                } footer: {
                    Text("Tap to connect. Hosts should be accessible via Tailscale or local network.")
                }

                Section {
                    Button {
                        showingAddHost = true
                    } label: {
                        Label("Add New Host", systemImage: "plus.circle.fill")
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color.black)
        .sheet(isPresented: $showingAddHost) {
            NavigationStack {
                AddHostSheet()
            }
        }
        .sheet(item: $editingHost) { host in
            NavigationStack {
                EditHostSheet(host: host)
            }
        }
    }
}

struct HostRowView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    let host: SSHHost

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
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var isConnected: Bool {
        connectionManager.currentHost?.id == host.id && connectionManager.isConnected
    }
}

struct AddHostSheet: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var hostname = ""
    @State private var port = "3847"
    @State private var username = ""
    @State private var password = ""
    @State private var useKeyAuth = false

    var body: some View {
        Form {
            Section {
                TextField("Display Name", text: $name)
                #if os(iOS)
                TextField("Hostname / IP", text: $hostname)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                #else
                TextField("Hostname / IP", text: $hostname)
                    .autocorrectionDisabled()
                #endif
                TextField("Port", text: $port)
                    .keyboardType(.numberPad)
            } header: {
                Text("Host Details")
            }

            Section {
                #if os(iOS)
                TextField("Username", text: $username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                #else
                TextField("Username", text: $username)
                    .autocorrectionDisabled()
                #endif
                SecureField("Auth Token", text: $password)
            } header: {
                Text("Authentication")
            }

            Section {
                Text("For Tailscale, use the device's Tailscale IP (100.x.x.x).\nPort 3847 for WebSocket server.")
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
                Button("Add") {
                    saveHost()
                }
                .disabled(!isValid)
            }
        }
    }

    private var isValid: Bool {
        !name.isEmpty && !hostname.isEmpty && !username.isEmpty && Int(port) != nil
    }

    private func saveHost() {
        let host = SSHHost(
            name: name,
            hostname: hostname,
            port: Int(port) ?? 3847,
            username: username,
            password: password.isEmpty ? nil : password,
            useKeyAuth: useKeyAuth
        )
        connectionManager.addHost(host)
        dismiss()
    }
}

struct EditHostSheet: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @Environment(\.dismiss) var dismiss
    let host: SSHHost

    @State private var name = ""
    @State private var hostname = ""
    @State private var port = "3847"
    @State private var username = ""
    @State private var password = ""
    @State private var useKeyAuth = false

    var body: some View {
        Form {
            Section {
                TextField("Display Name", text: $name)
                #if os(iOS)
                TextField("Hostname / IP", text: $hostname)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                #else
                TextField("Hostname / IP", text: $hostname)
                    .autocorrectionDisabled()
                #endif
                TextField("Port", text: $port)
                    .keyboardType(.numberPad)
            } header: {
                Text("Host Details")
            }

            Section {
                #if os(iOS)
                TextField("Username", text: $username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                #else
                TextField("Username", text: $username)
                    .autocorrectionDisabled()
                #endif
                SecureField("Auth Token", text: $password)
            } header: {
                Text("Authentication")
            }
        }
        .navigationTitle("Edit Host")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    updateHost()
                }
                .disabled(!isValid)
            }
        }
        .onAppear {
            name = host.name
            hostname = host.hostname
            port = String(host.port)
            username = host.username
            password = host.password ?? ""
            useKeyAuth = host.useKeyAuth
        }
    }

    private var isValid: Bool {
        !name.isEmpty && !hostname.isEmpty && !username.isEmpty && Int(port) != nil
    }

    private func updateHost() {
        var updated = host
        updated.name = name
        updated.hostname = hostname
        updated.port = Int(port) ?? 3847
        updated.username = username
        updated.password = password.isEmpty ? nil : password
        updated.useKeyAuth = useKeyAuth
        connectionManager.updateHost(updated)
        dismiss()
    }
}
