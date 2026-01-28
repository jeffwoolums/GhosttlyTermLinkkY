//
//  QuickCommandsSettingsView.swift
//  GhosttlyTermLinkkY
//

import SwiftUI

struct QuickCommandsSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingAddCommand = false
    @State private var editingCommand: QuickCommand?
    
    var body: some View {
        List {
            Section {
                ForEach(settingsManager.quickCommands) { command in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(command.name)
                                .font(.headline)
                            Text(command.command)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontDesign(.monospaced)
                        }
                    }
                    .swipeActions {
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
            }
            
            Section {
                Button {
                    showingAddCommand = true
                } label: {
                    Label("Add Command", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Quick Commands")
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showingAddCommand) {
            AddQuickCommandSheet()
        }
        .sheet(item: $editingCommand) { command in
            EditQuickCommandSheet(command: command)
        }
    }
}

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
                    .textInputAutocapitalization(.never)
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
                    .textInputAutocapitalization(.never)
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
