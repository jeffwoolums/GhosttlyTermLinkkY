//
//  QuickCommandsSettingsView.swift
//  GhosttlyTermLinkkY
//
//  Manage quick commands - presented as sheet.
//

import SwiftUI

struct QuickCommandsSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAddCommand = false
    @State private var editingCommand: QuickCommand?

    var body: some View {
        NavigationStack {
            List {
                ForEach(settingsManager.quickCommands) { command in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(command.name)
                                .font(.headline)
                            Text(command.command)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontDesign(.monospaced)
                        }
                        Spacer()
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            settingsManager.removeQuickCommand(command)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            editingCommand = command
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
                .onMove { from, to in
                    settingsManager.moveQuickCommand(from: from, to: to)
                }
                
                Section {
                    Button {
                        showingAddCommand = true
                    } label: {
                        Label("Add Command", systemImage: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Quick Commands")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddCommand) {
                AddQuickCommandSheet()
            }
            .sheet(item: $editingCommand) { command in
                EditQuickCommandSheet(command: command)
            }
        }
    }
}

// MARK: - Add Command

struct AddQuickCommandSheet: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var command = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                
                TextField("Command", text: $command)
                    .fontDesign(.monospaced)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            }
            .navigationTitle("Add Command")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        settingsManager.addQuickCommand(QuickCommand(name: name, command: command))
                        dismiss()
                    }
                    .disabled(name.isEmpty || command.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Command

struct EditQuickCommandSheet: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss
    let command: QuickCommand
    
    @State private var name = ""
    @State private var commandText = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                
                TextField("Command", text: $commandText)
                    .fontDesign(.monospaced)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            }
            .navigationTitle("Edit Command")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = command
                        updated.name = name
                        updated.command = commandText
                        settingsManager.updateQuickCommand(updated)
                        dismiss()
                    }
                    .disabled(name.isEmpty || commandText.isEmpty)
                }
            }
            .onAppear {
                name = command.name
                commandText = command.command
            }
        }
    }
}
