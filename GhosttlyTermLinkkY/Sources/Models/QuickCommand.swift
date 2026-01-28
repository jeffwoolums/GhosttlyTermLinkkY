//
//  QuickCommand.swift
//  GhosttlyTermLinkkY
//

import Foundation

struct QuickCommand: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var command: String
    var category: String?
    var icon: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        category: String? = nil,
        icon: String? = nil
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.category = category
        self.icon = icon
    }
    
    static let defaults: [QuickCommand] = [
        QuickCommand(name: "Claude Code", command: "claude", category: "AI", icon: "brain"),
        QuickCommand(name: "List Files", command: "ls -la", category: "Files", icon: "folder"),
        QuickCommand(name: "Git Status", command: "git status", category: "Git", icon: "arrow.triangle.branch"),
        QuickCommand(name: "Git Pull", command: "git pull", category: "Git", icon: "arrow.down"),
        QuickCommand(name: "Git Push", command: "git push", category: "Git", icon: "arrow.up"),
        QuickCommand(name: "Git Log", command: "git log --oneline -10", category: "Git", icon: "list.bullet"),
        QuickCommand(name: "NPM Install", command: "npm install", category: "Node", icon: "shippingbox"),
        QuickCommand(name: "NPM Run Dev", command: "npm run dev", category: "Node", icon: "play.fill"),
        QuickCommand(name: "Clear Screen", command: "clear", category: "Terminal", icon: "xmark.circle"),
        QuickCommand(name: "Disk Usage", command: "df -h", category: "System", icon: "externaldrive"),
        QuickCommand(name: "Memory", command: "free -h || vm_stat", category: "System", icon: "memorychip"),
        QuickCommand(name: "Processes", command: "ps aux | head -20", category: "System", icon: "cpu"),
    ]
}
