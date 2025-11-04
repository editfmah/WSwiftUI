//
//  Text.swift
//  SWWebAppServer
//
//  Created by Adrian on 01/07/2025.
//

import Foundation

private func escapeForJSTemplate(_ s: String) -> String {
    var out = s
    out = out.replacingOccurrences(of: "\\", with: "\\\\")
    out = out.replacingOccurrences(of: "`", with: "\\`")
    out = out.replacingOccurrences(of: "${", with: "\\${")
    return out
}

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
    func Text(_ text: String) -> WebElement {
        var result: WebElement?
        
        // if we’re inside a picker, branch on its type…
        if let parent = parent {
            if let parent = parent as? WebPickerElement, parent.type == .combo {
                
                result = WebElement()
                result?.title(text)
                parent.addAttribute(.item(result!))
                
            } else if let parent = parent as? WebPickerElement, parent.type == .radio(.horizontal) || parent.type == .radio(.vertical) {
                
                let value = parent.value
                
                let outer = create { element in
                    element.elementName = "div"
                    element.class("form-check")
                    switch parent.type {
                    case .radio(let alignment):
                        if alignment == .horizontal {
                            element.class("form-check-inline")
                        }
                    default:
                        break
                    }
                    element.class(parent.builderId)
                }
                
                stack.append(outer)
                
                // generate the input
                result = create { element in
                    
                    element.elementName = "input"
                    element.class("form-check-input")
                    element.type("radio")
                    element.id("\(element.builderId)")
                    element.name(parent.builderId)
                    element.label(text)
                    
                    if let value {
                        element.addAttribute(.custom("onChange=\"if (this.checked) { updateWebVariable\(value.builderId)(this.value); };\""))
                        // initial value
                        if value.asBool() {
                            element.checked()
                        }
                        // register callbacks for updates to the bound variable
                        element.script("""
                            function updateVariable\(element.builderId)(value) {
                                // (Optional) keep the attribute in sync for SSR/HTML snapshots
                                if (value == \(element.builderId).value) {
                                    \(element.builderId).checked = true;
                                    \(element.builderId).setAttribute('checked', 'checked');
                                } else {
                                    \(element.builderId).removeAttribute('checked');
                                }
                            }
                            addCallback\(value.builderId)(updateVariable\(element.builderId));
                        """)
                    }
                    
                }
                
                stack.removeAll(where: { $0.builderId == outer.builderId })
                
            } else if let parent = parent as? WebPickerElement,
                      [
                        .segmented(.primary),
                        .segmented(.danger),
                        .segmented(.dark),
                        .segmented(.info),
                        .segmented(.light),
                        .segmented(.secondary),
                        .segmented(.success),
                        .segmented(.warning)
                      ].contains(parent.type) {
                
                let value = parent.value
                
                result = create { element in
                    
                    element.elementName = "button"
                    element.class("btn")
                    var thisVariant = ""
                    switch parent.type {
                    case .segmented(let variant):
                        thisVariant = variant.rawValue
                        if let value {
                            if value.asBool() {
                                element.class("btn-\(thisVariant)")
                            } else {
                                element.class("btn-outline-\(thisVariant)")
                            }
                        }
                    default:
                        break
                    }
                    element.class(parent.builderId)
                    element.type("button")
                    
                    // set the text
                    element.innerHTML(text.escapedForHTML())
                    
                    if let value {
                        element.addAttribute(.custom("onClick=\"updateWebVariable\(value.builderId)(this.value);\""))
                        // register callbacks for updates to the bound variable
                        element.script("""
                            function updateVariable\(element.builderId)(value) {
                                // look through all of the buttons in this group and set them to 
                                var thisGroup = document.querySelectorAll('.\(parent.builderId)');
                                thisGroup.forEach(function(btn) {
                                    if (btn.value == value) {
                                        btn.classList.remove('btn-outline-\(thisVariant)');
                                        btn.classList.add('btn-\(thisVariant)');
                                    } else {
                                        btn.classList.remove('btn-\(thisVariant)');
                                        btn.classList.add('btn-outline-\(thisVariant)');
                                    }
                                });
                            }
                            addCallback\(value.builderId)(updateVariable\(element.builderId));
                        """)
                    }
                }
                
            }
        }
        
        if result == nil {
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
        }
        
        return result!
        
    }
    
    
    // MARK: – WString binding
    @discardableResult
    func Text(_ binding: WebVariableElement) -> WebElement {
        
        var result: WebElement?
        
        WrapInLayoutContainer {
            result = create { element in
                element.elementName = "span"
                element.class(element.builderId)
                
                // initial value
                element.addAttribute(.innerHTML(binding.asString()))
                
                // register a callback for updates
                element.script("""
                    function updateVariable\(element.builderId)(value) {
                        \(element.builderId).innerText = value;
                    }
                    addCallback\(binding.builderId)(updateVariable\(element.builderId));
                """)
                
                element.class("col")
            }
        }
        return result!
    }
    
    // MARK: – Formatted text with bound variables
    @discardableResult
    func Text(_ format: String, _ bindings: WebVariableElement...) -> WebElement {
        var result: WebElement?

        // Server-side initial render: replace $0, $1, ... with current bound values
        var initial = format
        for (idx, b) in bindings.enumerated() {
            initial = initial.replacingOccurrences(of: "$\(idx)", with: b.asString())
        }

        WrapInLayoutContainer {
            result = create { element in
                element.elementName  = "span"
                element.class(element.builderId)
                element.class("text")
                // Safe initial content for SSR/HTML snapshots
                element.innerHTML(initial.escapedForHTML())
                element.class("col")

                // Client-side dynamic updates: when any binding changes, re-render the formatted string
                let jsFormat = escapeForJSTemplate(format)
                var script = """
                (function(){
                    var fmt = `\(jsFormat)`;
                    var values = [];
                    function render(){
                        try {
                            var out = fmt.replace(/\\$(\\d+)/g, function(_, idx){
                                var i = parseInt(idx, 10);
                                var v = values[i];
                                return (v == null) ? '' : String(v);
                            });
                            \(element.builderId).textContent = out;
                        } catch(e) {
                            // fail silently
                        }
                    }
                """

                // Register callbacks for each binding to update and re-render
                for (i, b) in bindings.enumerated() {
                    script += """
                        addCallback\(b.builderId)(function(value){ values[\(i)] = value; render(); });
                    """
                }

                script += """
                    // Note: initial content already SSR-rendered; dynamic rendering occurs on first update
                })();
                """

                element.script(script)
            }
        }

        return result!
    }
    
}
