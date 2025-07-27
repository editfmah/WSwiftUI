//
//  Text.swift
//  SWWebAppServer
//
//  Created by Adrian on 01/07/2025.
//

import Foundation

internal extension String {
    /// Escapes the string for safe HTML output.
    ///
    /// This method replaces the following characters with their HTML entity equivalents:
    /// - Parameter preserveLineBreaks: If `true`, converts newline characters (`\n`) into `<br>` tags.
    /// - Returns: A new `String` with HTML entities escaped.
    func escapedForHTML(preserveLineBreaks: Bool = true) -> String {

        // 2) Fallback manual mapping if CFXML isn’t available
        let escapeMap: [Character: String] = [
            // Basic XML
            "&":  "&amp;",
            "<":  "&lt;",
            ">":  "&gt;",
            "\"": "&quot;",
            "'":  "&#39;",
            "/":  "&#x2F;",
            
            // Whitespace
            " ":  "&nbsp;",    // non‑breaking space U+00A0
            "\t": "&#9;",      // tab
            "\r": "<br>",
            "\n": "<br>",     // line feed
            
            // Punctuation
            "¡": "&iexcl;",
            "¢": "&cent;",
            "£": "&pound;",
            "¤": "&curren;",
            "¥": "&yen;",
            "¦": "&brvbar;",
            "§": "&sect;",
            "¨": "&uml;",
            "©": "&copy;",
            "ª": "&ordf;",
            "«": "&laquo;",
            "¬": "&not;",
            "®": "&reg;",
            "¯": "&macr;",
            "°": "&deg;",
            "±": "&plusmn;",
            "²": "&sup2;",
            "³": "&sup3;",
            "´": "&acute;",
            "µ": "&micro;",
            "¶": "&para;",
            "·": "&middot;",
            "¸": "&cedil;",
            "¹": "&sup1;",
            "º": "&ordm;",
            "»": "&raquo;",
            "¼": "&frac14;",
            "½": "&frac12;",
            "¾": "&frac34;",
            "¿": "&iquest;",
            
            // Mathematical
            "×": "&times;",
            "÷": "&divide;",
            "‰": "&permil;",
            "−": "&minus;",    // U+2212 minus sign
            "–": "&ndash;",    // en dash
            "—": "&mdash;",    // em dash
            "•": "&bull;",     // bullet
            "…": "&hellip;",
            
            // Quotes
            "‘": "&lsquo;",
            "’": "&rsquo;",
            "‚": "&sbquo;",
            "“": "&ldquo;",
            "”": "&rdquo;",
            "„": "&bdquo;",
            
            // Single-angle quotes
            "‹": "&lsaquo;",
            "›": "&rsaquo;",
            
            // Greek (a few)
            "α": "&alpha;",
            "β": "&beta;",
            "γ": "&gamma;",
            "Δ": "&Delta;",
            "π": "&pi;",
            "φ": "&phi;",
            
            // Currency
            "€": "&euro;"
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

        if preserveLineBreaks {
            return result.replacingOccurrences(of: "\n", with: "<br>")
        }
        return result
    }
}


public extension CoreWebEndpoint {
    
    // MARK: – Plain text
    @discardableResult
    func Text(_ text: String) -> WebCoreElement {
        var result: WebCoreElement?
        
        // if we’re inside a picker, branch on its type…
        if let parent = parent, parent.isPicker(), let type = parent.pickerType() {
            switch type {
                case .dropdown:
                    result = create { element in
                        element.elementName  = "option"
                        element.class("text")
                        element.innerHTML(text)
                        element.class("col")
                    }
                case .segmented:
                    result = create { element in
                        element.elementName  = "button"
                        element.class("\(element.builderId) btn btn-secondary text")
                        element.innerHTML(text)
                        // the <button> needs a "button" type
                        element.script("\(element.builderId).type = 'button';")
                        element.class("col")
                    }
                default:
                    break
            }
        }
        WrapInLayoutContainer {
            // default (no picker)
            result = create { element in
                element.elementName  = "span"
                element.class("text")
                // we need to ensure that the text output is safe for HTML, so we escape it
                element.innerHTML(text.escapedForHTML())
                element.class("col")
            }
        }
        
        return result!
        
    }
    
    
    // MARK: – WString binding
    @discardableResult
    func Text(_ binding: WebVariableElement) -> WebCoreElement {
        
        var result: WebCoreElement?
        
        WrapInLayoutContainer {
            result = create { element in
                element.elementName = "span"
                element.class(element.builderId)
                
                // initial value
                element.script("""
            \(element.builderId).innerText = '\(binding.asString())');
            """)
                
                // poll for updates
                element.script("""
            l\(element.builderId)();
            function l\(element.builderId)() {
              const rl = () => {
                \(element.builderId).innerText = \(binding.builderId);
                return setTimeout(rl, 500);
              };
              rl();
            }
            """)
                
                element.class("col")
            }
        }
        return result!
    }
    
}
