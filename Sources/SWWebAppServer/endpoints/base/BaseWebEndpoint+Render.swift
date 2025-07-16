//
//  BaseWebEndpoint+Render.swift
//  SWWebAppServer
//
//  Created by Adrian on 04/07/2025.
//

let tab = "    "

internal extension BaseWebEndpoint {
    
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
        
        pageContent += "</html>\n"
        return pageContent
    }
    
    // MARK: –– Render a WebCoreElement recursively
    private func render(_ element: WebCoreElement, indent: String) -> String {
        // 1. collect attributes, grouping multi-valued ones
        var classValues: [String] = []
        var styleValues: [String] = []
        var otherParts: [String] = []
        var innerText: String? = nil
        var scripts: [String] = []
        
        // insert the registration script as the first script
        let registrationScript = "var \(element.builderId) = document.getElementsByClassName('\(element.builderId)')[0];"
        scripts.append(registrationScript)

        for attr in element.attributes {
            switch attr {
            case .class(let v):
                classValues.append(v)

            case .style(let v):
                styleValues.append(v)

            case .id(let v):           otherParts.append("id=\"\(v)\"")
            case .name(let v):         otherParts.append("name=\"\(v)\"")
            case .value(let v):        otherParts.append("value=\"\(v)\"")
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
            case .internalType(let t): otherParts.append("data-internal-type=\"\(t)\"")
            case .script(let js):      scripts.append(js)
            case .innerHTML(let html): innerText = html
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
        parts.append(contentsOf: otherParts)

        // 3. open tag (no “>” or newline yet)
        let attrString = parts.isEmpty ? "" : " " + parts.joined(separator: " ")
        var result = "\(indent)<\(element.elementName)\(attrString)"

        // flags
        let hasInner   = innerText != nil
        let hasChildren = !element.subElements.isEmpty
        let hasScripts = !scripts.isEmpty

        // 4a. nothing inside? close inline
        if !hasInner && !hasChildren && !hasScripts {
            result += "></\(element.elementName)>\n"
            return result
        }

        // 4b. there is something—emit children in order
        result += ">\n"
        let childIndent = indent + tab

        // 4b.i innerHTML first
        if let html = innerText {
            result += "\(childIndent)\(html)\n"
        }

        // 4b.ii then any nested elements
        for child in element.subElements {
            result += render(child, indent: childIndent)
        }

        // 4c. close tag
        result += "\(indent)</\(element.elementName)>\n"
        
        // 4b.iii then any scripts
        for js in scripts {
            result += "\(childIndent)<script>\(js)</script>\n"
        }
        return result

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
        case .script(let src, let async, let `defer`, let type, let integrity, let crossOrigin):
            var parts: [String] = ["src=\"\(src)\""]
            if async               { parts.append("async") }
            if `defer`             { parts.append("defer") }
            if let t = type        { parts.append("type=\"\(t)\"") }
            if let i = integrity   { parts.append("integrity=\"\(i)\"") }
            if let co = crossOrigin{ parts.append("crossorigin=\"\(co)\"") }
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
