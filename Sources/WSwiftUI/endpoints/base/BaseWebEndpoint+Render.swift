//
//  BaseWebEndpoint+Render.swift
//  SWWebAppServer
//
//  Created by Adrian on 04/07/2025.
//

let tab = "    "

fileprivate extension WebElement {
    var value: String {
        get {
            if let value = attributes.first(where: { if case .value(_) = $0 { return true }
                return false
            }) {
                switch value {
                    case .value(let v): return v
                    default: return ""
                }
            }
            return ""
        }
    }
    var title: String {
        get {
            if let title = attributes.first(where: { if case .title(_) = $0 { return true }
                return false
            }) {
                switch title {
                    case .title(let v): return v
                    default: return ""
                }
            }
            return ""
        }
    }
    var isSelected: Bool {
        get {
            return attributes.contains { if case .selected = $0 { return true }
                return false
            }
        }
    }
    var isDisabled: Bool {
        get {
            return attributes.contains { if case .disabled = $0 { return true }
                return false
            }
        }
    }
}

internal extension CoreWebEndpoint {
    
    /// Override this in your endpoints to supply whatever head elements you need.
    
    func renderWebPage() -> String {
        var pageContent = "<html lang=\"en\">\n"
        
        // render head
        pageContent += "\(tab)<head>\n"
        let innerIndent = tab + tab
        for element in self.headAttributes {
            pageContent += render(element, indent: innerIndent)
        }
        pageContent += "\(tab)</head>\n"
        
        // render body
        pageContent += "\(tab)<body>\n"
        if let root = webRootElement {
            for webElement in root.subElements {
                pageContent += render(webElement, indent: innerIndent)
            }
        }
        pageContent += "\(tab)</body>\n"
        
        // render domLoaded scripts
        if !domLoadedScripts.isEmpty {
            pageContent += "\(tab)<script>\n"
            pageContent += "\(tab)\(tab)document.addEventListener('DOMContentLoaded', function() {\n"
            for script in domLoadedScripts {
                pageContent += "\(tab)\(tab)\(tab)\(script)\n"
            }
            pageContent += "\(tab)\(tab)});\n"
            pageContent += "\(tab)</script>\n"
        }

        pageContent += "</html>\n"
        return pageContent
    }
    
    // MARK: –– Render a WebCoreElement recursively
    private func render(_ element: WebElement, indent: String) -> String {
        // 1. collect attributes, grouping multi-valued ones
        var classValues: [String] = []
        var styleValues: [String] = []
        var otherParts: [String] = []
        var innerText: String? = nil
        var scripts: [String] = []
        var items: [String] = [] // internal items for combos, dropdowns, segmented controls etc.
        var label: String? = nil
        var initialValue: Any? = nil
        var value: Any? = nil
        var errorMessage: String? = nil
        var validators: [ValidationCondition] = []
        var dontRegister = false
        
        for attr in element.attributes {
            switch attr {
                case .class(let v):
                    classValues.append(v)
                    
                case .style(let v):
                    styleValues.append(v)
                    
                case .id(let v):           otherParts.append("id=\"\(v)\"")
                case .name(let v):         otherParts.append("name=\"\(v)\"")
                case .value(let v):        value = v
                case .type(let v):         otherParts.append("type=\"\(v)\"")
                case .placeholder(let v):  otherParts.append("placeholder=\"\(v)\"")
                case .required:            otherParts.append("required")
                case .disabled:            otherParts.append("disabled")
                case .readonly:            otherParts.append("readonly")
                case .checked:             otherParts.append("checked")
                case .selected:            otherParts.append("selected")
                case .src(let v):          otherParts.append("src=\"\(v)\"")
                case .href(let v):         otherParts.append("href=\"\(v)\"")
                case .alt(let v):          otherParts.append("alt=\"\(v)\"")
                case .title(let v):        otherParts.append("title=\"\(v)\"")
                case .data(let key):       otherParts.append("data-\(key)")
                case .custom(let s):       otherParts.append(s)
                case .pair(let k, let v):  otherParts.append("\(k)=\"\(v)\"")
                case .script(let js):      scripts.append(js)
                case .innerHTML(let html): innerText = html
                case .domLoadedScript(let script): domLoadedScripts.append(script)
                case .item(_):
                    break;
                case .variant(_):
                    break;
                case .parent(_):
                    break;
                case .label(let text):
                    label = text
                case .initialValue(let value):
                    initialValue = value
                case .errorMessage(let message):
                    errorMessage = message
                    classValues.append("border-danger")
                case .validation(let condition):
                    validators.append(condition)
                case .dontRegisterObject:
                    dontRegister = true
            }
        }
        
        if !dontRegister {
            // insert the registration script as the first script
            let registrationScript = "var \(element.builderId) = document.getElementsByClassName('\(element.builderId)')[0];"
            scripts.insert(registrationScript, at: 0)
        }
        
        // build the items up now if there are any
        if let picker = element as? WebPickerElement {
            
            // pick out only the subitems
            let subItems  = element.attributes.filter {
                if case .item = $0 { return true }
                return false
            }
            
            switch picker.type {
                case .combo:
                    // render all items as <option> elements
                    for item in subItems {
                        if case .item(let item) = item {
                            var option = "<option value=\"\(item.value)\""
                            if item.isSelected { option += " selected" }
                            if item.isDisabled { option += " disabled" }
                            option += ">\(item.title)</option>"
                            items.append(option)
                        }
                    }
                case .segmented:
                    break;
                case .radio:
                    break;
                case .colorPicker:
                    break;
            }
        }
        
        // 2. now build the final attribute list
        var parts: [String] = []
        
        if !classValues.isEmpty {
            // join with spaces
            let allClasses = classValues.joined(separator: " ")
            parts.append("class=\"\(allClasses)\"")
        }
        if !styleValues.isEmpty {
            // merge multiple style strings with semicolons
            let allStyles = styleValues.joined(separator: ";")
            parts.append("style=\"\(allStyles)\"")
        }
        if let initialValue = initialValue {
            parts.append("value=\"\(initialValue)\"")
            if let v = initialValue as? String {
                domLoadedScripts.append("updateWebVariable\(element.builderId)(`\(v)`);")
            } else if let v = initialValue as? Int {
                domLoadedScripts.append("updateWebVariable\(element.builderId)(\(v));")
            } else if let v = initialValue as? Double {
                domLoadedScripts.append("updateWebVariable\(element.builderId)(\(v));")
            } else if let v = initialValue as? Bool {
                domLoadedScripts.append("updateWebVariable\(element.builderId)(\(v ? "true" : "false"));")
            } else if let v = initialValue as? [String: Any] {
                domLoadedScripts.append("updateWebVariable\(element.builderId)(\(v.map { "\"\($0)\":\($1)" }.joined(separator: ",")));")
            } else if let v = initialValue as? [String: String] {
                domLoadedScripts.append("updateWebVariable\(element.builderId)(\(v.map { "\"\($0)\":\"\($1)\"" }.joined(separator: ",")));")
            } else if let v = initialValue as? [Int] {
                domLoadedScripts.append("updateWebVariable\(element.builderId)(\(v.map { "\($0)" }.joined(separator: ",")));")
            } else if let v = initialValue as? [String] {
                domLoadedScripts.append("updateWebVariable\(element.builderId)(\(v.map { "\"\($0)\"" }.joined(separator: ",")));")
            }
        } else if let value = value {
            parts.append("value=\"\(value)\"")
        }
        parts.append(contentsOf: otherParts)
        
        // now compile an encoded set of validators
        if validators.isEmpty == false {
            parts.append("validation=\" \( validators.map { $0.encoded }.joined(separator: ","))\"")
        }
        
        // use an array of strings to build the result as efficiently as possible
        var result: [String] = []
        
        // check for a label to this element
        if let labelText = label {
            result.append("\(indent)<label for=\"\(element.builderId)\">\(labelText)</label>\n")
        }
        
        // 3. open tag (no “>” or newline yet)
        let attrString = parts.isEmpty ? "" : " " + parts.joined(separator: " ")
        result.append("\(indent)<\(element.elementName)\(attrString)")
        
        // flags
        let hasInner   = innerText != nil
        let hasChildren = !element.subElements.isEmpty
        let hasScripts = !scripts.isEmpty
        
        // 4a. nothing inside? close inline
        if !hasInner && !hasChildren && !hasScripts && items.isEmpty {
            result.append("></\(element.elementName)>\n")
            return result.joined(separator: "")
        }
        
        // 4b. there is something—emit children in order
        result.append(">")
        if element.subElements.isEmpty == false {
            result.append("\n")
        }
        let childIndent = indent + tab
        
        // 4b.i innerHTML first
        if let html = innerText, element.subElements.isEmpty {
            result.append("\(html)")
        } else if let html = innerText {
            result.append("\(childIndent)\(html)\n")
        } else if items.isEmpty == false {
            result.append(items.joined(separator: "\n"))
        }
        
        // 4b.ii then any nested elements
        for child in element.subElements {
            result.append(render(child, indent: childIndent))
        }
        
        // 4c. close tag
        if element.subElements.isEmpty == false {
            result.append("\(indent)</\(element.elementName)>\n")
        } else {
            result.append("</\(element.elementName)>\n")
        }
        
        // 4b.iii then any scripts
        for js in scripts {
            result.append("\(childIndent)<script>\(js)</script>\n")
        }
        
        // now see if there is an inline error message to show
        if let errorMessage = errorMessage {
            result.append("\(childIndent)<div style=\"font-size: x-small; color: red;\">\(errorMessage)</div>\n")
        }
        
        // now see if there are any validation items, which may need to show an error message
        if validators.isEmpty == false {
            result.append("\(childIndent)<div class=\"text-danger font-weight-light\" id=\"validation_error_\(element.builderId)\"></div>\n")
        }
        return result.joined(separator: "")
        
    }
    
    
    /// Renders a single head element with the given indent and a trailing newline.
    private func render(_ element: WebCoreHeadElement, indent: String) -> String {
        switch element {
            case .title(let text):
                return "\(indent)<title>\(text)</title>\n"
                
            case .base(let href):
                return "\(indent)<base href=\"\(href)\" />\n"
                
                // MARK: Meta tags
            case .metaCharset(let charset):
                return "\(indent)<meta charset=\"\(charset)\" />\n"
                
            case .metaHttpEquiv(let httpEquiv, let content):
                return "\(indent)<meta http-equiv=\"\(httpEquiv)\" content=\"\(content)\" />\n"
                
            case .metaName(let name, let content):
                return "\(indent)<meta name=\"\(name)\" content=\"\(content)\" />\n"
                
            case .metaProperty(let prop, let content):
                return "\(indent)<meta property=\"\(prop)\" content=\"\(content)\" />\n"
                
            case .metaViewport(let content):
                return "\(indent)<meta name=\"viewport\" content=\"\(content)\" />\n"
                
            case .metaThemeColor(let color):
                return "\(indent)<meta name=\"theme-color\" content=\"\(color)\" />\n"
                
            case .metaDescription(let desc):
                return "\(indent)<meta name=\"description\" content=\"\(desc)\" />\n"
                
            case .metaApplicationName(let name):
                return "\(indent)<meta name=\"application-name\" content=\"\(name)\" />\n"
                
            case .metaMobileWebAppCapable(let capable):
                let val = capable ? "yes" : "no"
                return "\(indent)<meta name=\"mobile-web-app-capable\" content=\"\(val)\" />\n"
                
                // MARK: Link tags
            case .link(let rel, let href, let type, let sizes, let color, let attrs):
                var parts: [String] = ["rel=\"\(rel.stringValue)\"", "href=\"\(href)\""]
                if let t = type        { parts.append("type=\"\(t)\"") }
                if let s = sizes       { parts.append("sizes=\"\(s)\"") }
                if let c = color       { parts.append("color=\"\(c)\"") }
                if let extra = attrs {
                    for (k,v) in extra { parts.append("\(k)=\"\(v)\"") }
                }
                return "\(indent)<link \(parts.joined(separator: " ")) />\n"
                
                // MARK: Scripts & Styles
            case .script(let src, let async, let `defer`, let type, let integrity, let crossOrigin, let attributes):
                var parts: [String] = ["src=\"\(src)\""]
                if async               { parts.append("async") }
                if `defer`             { parts.append("defer") }
                if let t = type        { parts.append("type=\"\(t)\"") }
                if let i = integrity   { parts.append("integrity=\"\(i)\"") }
                if let co = crossOrigin{ parts.append("crossorigin=\"\(co)\"") }
                if let extra = attributes {
                    for (k,v) in extra { parts.append("\(k)=\"\(v)\"") }
                }
                return "\(indent)<script \(parts.joined(separator: " "))></script>\n"
                
            case .inlineScript(let code):
                return "\(indent)<script>\n\(indent)\(tab)\(code)\n\(indent)</script>\n"
                
            case .styleLink(let href):
                return "\(indent)<link rel=\"stylesheet\" href=\"\(href)\" />\n"
                
            case .inlineStyle(let css):
                return "\(indent)<style>\n\(indent)\(tab)\(css)\n\(indent)</style>\n"
                
                // MARK: Comment & Custom
            case .comment(let text):
                return "\(indent)<!-- \(text) -->\n"
                
            case .custom(let tag, let attributes, let innerHTML):
                let attrs = attributes.map { "\($0)=\"\($1)\"" }.joined(separator: " ")
                if let inner = innerHTML {
                    return "\(indent)<\(tag) \(attrs)>\(inner)</\(tag)>\n"
                } else {
                    return "\(indent)<\(tag) \(attrs) />\n"
                }
        }
    }
}
