//
//  StringEscaping.swift
//  WSwiftUI
//

import Foundation

internal extension String {

    /// Escapes a string for safe embedding inside a JavaScript single-quoted string literal.
    /// Handles backslashes, single quotes, newlines, carriage returns, and other control characters.
    func jsEscaped() -> String {
        var result = ""
        result.reserveCapacity(self.count)
        for char in self {
            switch char {
            case "\\":  result += "\\\\"
            case "'":   result += "\\'"
            case "\"":  result += "\\\""
            case "\n":  result += "\\n"
            case "\r":  result += "\\r"
            case "\t":  result += "\\t"
            default:    result.append(char)
            }
        }
        return result
    }

    /// Escapes a string for safe embedding inside an HTML attribute value (double-quoted).
    /// Handles ampersands, double quotes, less-than, greater-than, newlines, and carriage returns.
    func htmlAttrEscaped() -> String {
        var result = self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "&#10;")
            .replacingOccurrences(of: "\r", with: "&#13;")
        return result
    }

    /// Escapes a string for safe embedding as HTML text content (between tags).
    func htmlEscaped() -> String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
