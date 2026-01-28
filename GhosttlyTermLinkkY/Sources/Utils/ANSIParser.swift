//
//  ANSIParser.swift
//  GhosttlyTermLinkkY
//
//  Parses ANSI escape sequences into AttributedString.
//  Handles SGR (Select Graphic Rendition) color codes:
//    - Standard colors (30-37, 90-97)
//    - 256-color mode (38;5;n)
//    - True color / 24-bit (38;2;r;g;b)
//    - Bold, dim, italic, underline
//    - Reset (0)
//

import SwiftUI

/// Converts raw terminal output containing ANSI escape codes
/// into a SwiftUI AttributedString with proper colors and styles.
struct ANSIParser {

    /// Parse a string with ANSI codes into an AttributedString
    static func parse(_ input: String, defaultColor: Color = .white) -> AttributedString {
        var result = AttributedString()
        var currentColor: Color = defaultColor
        var currentBold = false
        var currentDim = false
        var currentItalic = false
        var currentUnderline = false

        var i = input.startIndex

        while i < input.endIndex {
            // Look for ESC [ sequence
            if input[i] == "\u{1B}" {
                let next = input.index(after: i)
                if next < input.endIndex && input[next] == "[" {
                    // Parse the CSI sequence
                    let seqStart = input.index(after: next)
                    if let (params, endIdx) = parseCSIParams(input, from: seqStart) {
                        let terminator = input[endIdx]

                        if terminator == "m" {
                            // SGR - update current style
                            applySGR(params,
                                     color: &currentColor,
                                     bold: &currentBold,
                                     dim: &currentDim,
                                     italic: &currentItalic,
                                     underline: &currentUnderline,
                                     defaultColor: defaultColor)
                        }
                        // Skip other CSI sequences (cursor movement, etc.)

                        i = input.index(after: endIdx)
                        continue
                    }
                }
                // Malformed escape - skip the ESC byte
                i = input.index(after: i)
                continue
            }

            // Regular character - find the next escape or end
            let charStart = i
            while i < input.endIndex && input[i] != "\u{1B}" {
                i = input.index(after: i)
            }

            // Append the text segment with current style
            var segment = AttributedString(String(input[charStart..<i]))
            segment.foregroundColor = currentBold ? brighten(currentColor) : currentColor
            if currentDim {
                segment.foregroundColor = dim(currentColor)
            }
            if currentUnderline {
                segment.underlineStyle = .single
            }
            result += segment
        }

        return result
    }

    // MARK: - CSI Parsing

    /// Parse numeric parameters from a CSI sequence up to the terminating letter
    private static func parseCSIParams(_ str: String, from start: String.Index) -> ([Int], String.Index)? {
        var params: [Int] = []
        var current = ""
        var i = start

        while i < str.endIndex {
            let ch = str[i]

            if ch >= "0" && ch <= "9" {
                current.append(ch)
            } else if ch == ";" {
                params.append(Int(current) ?? 0)
                current = ""
            } else if ch >= "A" && ch <= "z" {
                // Terminating character
                params.append(Int(current) ?? 0)
                return (params, i)
            } else {
                // Unexpected character
                return nil
            }

            i = str.index(after: i)
        }
        return nil
    }

    // MARK: - SGR Application

    /// Apply SGR (Select Graphic Rendition) parameters to current style state
    private static func applySGR(_ params: [Int],
                                  color: inout Color,
                                  bold: inout Bool,
                                  dim: inout Bool,
                                  italic: inout Bool,
                                  underline: inout Bool,
                                  defaultColor: Color) {
        var i = 0
        let codes = params.isEmpty ? [0] : params

        while i < codes.count {
            let code = codes[i]

            switch code {
            case 0:
                color = defaultColor
                bold = false
                dim = false
                italic = false
                underline = false

            case 1: bold = true
            case 2: dim = true
            case 3: italic = true
            case 4: underline = true
            case 22: bold = false; dim = false
            case 23: italic = false
            case 24: underline = false

            // Standard foreground colors (30-37)
            case 30: color = .black
            case 31: color = .red
            case 32: color = .green
            case 33: color = .yellow
            case 34: color = .blue
            case 35: color = .purple
            case 36: color = .cyan
            case 37: color = .white

            // Bright foreground colors (90-97)
            case 90: color = Color(red: 0.5, green: 0.5, blue: 0.5)
            case 91: color = Color(red: 0.9, green: 0.4, blue: 0.4)
            case 92: color = Color(red: 0.4, green: 0.9, blue: 0.4)
            case 93: color = Color(red: 0.9, green: 0.9, blue: 0.4)
            case 94: color = Color(red: 0.4, green: 0.4, blue: 0.9)
            case 95: color = Color(red: 0.8, green: 0.4, blue: 0.9)
            case 96: color = Color(red: 0.4, green: 0.9, blue: 0.9)
            case 97: color = .white

            // Extended color: 38;5;n (256 color)
            case 38:
                if i + 1 < codes.count {
                    if codes[i + 1] == 5 && i + 2 < codes.count {
                        color = color256(codes[i + 2])
                        i += 2
                    } else if codes[i + 1] == 2 && i + 4 < codes.count {
                        // True color: 38;2;r;g;b
                        color = Color(red: Double(codes[i + 2]) / 255.0,
                                      green: Double(codes[i + 3]) / 255.0,
                                      blue: Double(codes[i + 4]) / 255.0)
                        i += 4
                    }
                }

            // Default foreground
            case 39: color = defaultColor

            // Background colors ignored (dark terminal bg assumed)
            case 40...49, 100...107: break

            default: break
            }

            i += 1
        }
    }

    // MARK: - Color Helpers

    private static func brighten(_ color: Color) -> Color {
        // Approximate brightening without mix API
        return color.opacity(0.8)
    }

    private static func dim(_ color: Color) -> Color {
        return color.opacity(0.5)
    }

    /// Map 256-color palette index to Color
    private static func color256(_ index: Int) -> Color {
        switch index {
        // 0-7: Standard colors
        case 0: return .black
        case 1: return .red
        case 2: return .green
        case 3: return .yellow
        case 4: return .blue
        case 5: return .purple
        case 6: return .cyan
        case 7: return .white

        // 8-15: Bright colors
        case 8: return Color(red: 0.5, green: 0.5, blue: 0.5)
        case 9: return Color(red: 0.9, green: 0.4, blue: 0.4)
        case 10: return Color(red: 0.4, green: 0.9, blue: 0.4)
        case 11: return Color(red: 0.9, green: 0.9, blue: 0.4)
        case 12: return Color(red: 0.4, green: 0.4, blue: 0.9)
        case 13: return Color(red: 0.8, green: 0.4, blue: 0.9)
        case 14: return Color(red: 0.4, green: 0.9, blue: 0.9)
        case 15: return .white

        // 16-231: 6x6x6 color cube
        case 16...231:
            let idx = index - 16
            let r = idx / 36
            let g = (idx % 36) / 6
            let b = idx % 6
            return Color(red: r == 0 ? 0 : (55.0 + Double(r) * 40.0) / 255.0,
                         green: g == 0 ? 0 : (55.0 + Double(g) * 40.0) / 255.0,
                         blue: b == 0 ? 0 : (55.0 + Double(b) * 40.0) / 255.0)

        // 232-255: Grayscale
        case 232...255:
            let gray = (Double(index - 232) * 10.0 + 8.0) / 255.0
            return Color(red: gray, green: gray, blue: gray)

        default: return .white
        }
    }
}
