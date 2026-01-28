//
//  TerminalLine.swift
//  GhosttlyTermLinkkY
//

import SwiftUI

struct TerminalLine: Identifiable {
    let id: UUID
    let text: String
    let color: Color
    let timestamp: Date
    let type: LineType
    
    enum LineType {
        case input
        case output
        case error
        case system
    }
    
    init(text: String, type: LineType = .output) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.timestamp = Date()
        
        switch type {
        case .input:
            self.color = .green
        case .output:
            self.color = .white
        case .error:
            self.color = .red
        case .system:
            self.color = .yellow
        }
    }
    
    static func input(_ text: String) -> TerminalLine {
        TerminalLine(text: "$ \(text)", type: .input)
    }
    
    static func output(_ text: String) -> TerminalLine {
        TerminalLine(text: text, type: .output)
    }
    
    static func error(_ text: String) -> TerminalLine {
        TerminalLine(text: text, type: .error)
    }
    
    static func system(_ text: String) -> TerminalLine {
        TerminalLine(text: "[\(text)]", type: .system)
    }
}
