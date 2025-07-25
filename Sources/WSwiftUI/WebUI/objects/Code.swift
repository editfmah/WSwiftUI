//
//  Code.swift
//  WSwiftUI
//
//  Created by Adrian on 25/07/2025.
//

import Foundation

internal extension String {
    /// Escapes the string for safe HTML output.
    ///
    /// This method replaces the following characters with their HTML entity equivalents:
    /// - Parameter preserveLineBreaks: If `true`, converts newline characters (`\n`) into `<br>` tags.
    /// - Returns: A new `String` with HTML entities escaped.
    func escapedForCode() -> String {

        // 2) Fallback manual mapping if CFXML isn’t available
        let escapeMap: [Character: String] = [
            // Basic XML
            "\t":  "&#9;",      // tab
            " ":  "&nbsp;",    // non‑breaking space U+00A0
        ]

        var result = String()
        result.reserveCapacity(self.count)

        for c in self {
            if let entity = escapeMap[c] {
                result.append(entity)
            } else {
                result.append(c)
            }
        }

        return result
    }
}

public enum CodeLanguage: String, CaseIterable {
    case swift = "swift"
    case javascript = "javascript"
    case python = "python"
    case html = "html"
    case css = "css"
    case xml = "xml"
    case json = "json"
    case sql = "sql"
    case bash = "bash"
    case csharp = "csharp"
    case java = "java"
    case kotlin = "kotlin"
}

public extension BaseWebEndpoint {
    
    // MARK: – Plain text
    @discardableResult
    func Code(language: CodeLanguage, _ text: String) -> WebCoreElement {
        var result: WebCoreElement?
        
        let lines = text.escapedForCode().components(separatedBy: "\n")
        
        WrapInLayoutContainer {
            result = create { element in
                element.elementName  = "pre"
                // we need to ensure that the text output is safe for HTML, so we escape it
                element.innerHTML("<code class = \"language-\(language.rawValue)\">\(text)</code>")
            }
        }
        
        return result!
        
    }
    
}
