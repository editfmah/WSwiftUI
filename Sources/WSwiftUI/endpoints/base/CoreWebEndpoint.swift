//
//  BaseWebEndpoint.swift
//  SWWebAppServer
//
//  Created by Adrian on 31/01/2025.
//

import Foundation

public enum PickerType {
    case dropdown
    case radio
    case check
    case modal
    case view
    case segmented
}

public typealias WebComposerClosure = (() -> Void)

public enum HeadItem {
    case css(String)
    case js(String)
    case meta(String)
    case link(String)
    case script(String)
    case style(String)
    case title(String)
    case raw(String)
}

public enum WebCoreHeadElement {
    case title(String)
    case base(href: String)
    
    // MARK: - Meta tags
    case metaCharset(String)                                   // <meta charset="…">
    case metaHttpEquiv(httpEquiv: String, content: String)     // <meta http-equiv="…" content="…">
    case metaName(name: String, content: String)               // <meta name="…" content="…">
    case metaProperty(property: String, content: String)       // <meta property="…" content="…">
    
    // convenience for very common names
    case metaViewport(content: String)                         // <meta name="viewport" content="…">
    case metaThemeColor(String)                                // <meta name="theme-color" content="…">
    case metaDescription(String)                               // <meta name="description" content="…">
    case metaApplicationName(String)                           // <meta name="application-name" content="…">
    case metaMobileWebAppCapable(Bool)                         // <meta name="mobile-web-app-capable" content="yes|no">
    // … you can add more “named” shortcuts here …
    
    // MARK: - Link tags
    case link(rel: LinkRel,
              href: String,
              type: String?        = nil,
              sizes: String?       = nil,
              color: String?       = nil,
              attributes: [String:String]? = nil)
    /// e.g.
    /// .link(.icon, href: "...", type: "image/png", sizes: "32x32")
    ///
    /// and you can still do arbitrary ones:
    /// .link(.other("preload"), href: "...", attributes: ["as":"font","crossorigin":""])
    
    public enum LinkRel: Equatable {
        case icon, stylesheet, appleTouchIcon, maskIcon, manifest, shortcutIcon
        case other(String)
        
        public var stringValue: String {
            switch self {
            case .icon:             return "icon"
            case .stylesheet:       return "stylesheet"
            case .appleTouchIcon:   return "apple-touch-icon"
            case .maskIcon:         return "mask-icon"
            case .manifest:         return "manifest"
            case .shortcutIcon:     return "shortcut icon"
            case .other(let s):     return s
            }
        }
    }
    
    // MARK: - Scripts & Styles
    case script(src: String,
                async: Bool     = false,
                defer: Bool     = false,
                type: String?   = nil,
                integrity: String? = nil,
                crossOrigin: String? = nil)
    case inlineScript(String)
    
    case styleLink(href: String)  // alias for .link(.stylesheet,…)
    case inlineStyle(String)
    
    // MARK: - Comments & Custom
    case comment(String)
    
    /// For anything else you haven’t explicitly modelled above
    case custom(tag: String,
                attributes: [String:String],
                innerHTML: String?)
}


public enum WebCoreElementAttribute {
    case `class`(String)
    case id(String)
    case name(String)
    case value(String)
    case type(String)
    case placeholder(String)
    case required
    case disabled
    case readonly
    case checked
    case selected
    case src(String)
    case href(String)
    case alt(String)
    case title(String)
    case style(String)
    case data(String)
    case custom(String)
    case pair(String, String)
    case script(String)
    case innerHTML(String)
    case item(WebElement)
    case variant(BootstrapVariant)
    case parent(Any)
    case label(String)
    case initialValue(Any)
    case errorMessage(String)
    case domLoadedScript(String)
    case validation(ValidationCondition)
}

internal enum WebCoreLayoutType {
    case vertical
    case horizontal
}

public class WebElement {
    
    public var builderId: String = UUID()
        .uuidString
        .replacingOccurrences(of: "-", with: "")
        .trimmingCharacters(in: CharacterSet.decimalDigits)
        .prefix(12)
        .lowercased()
    
    internal var attributes: [WebCoreElementAttribute] = []
    internal var layout: WebCoreLayoutType = .vertical
    public var elementName: String = "div"
    public var subElements: [WebElement] = []

    @discardableResult
    public func addAttribute(_ attribute: WebCoreElementAttribute) -> Self {
        attributes.append(attribute)
        return self
    }
    
    @discardableResult
    public func `class`(_ className: String)  -> Self {
        addAttribute(.class(className))
        return self
    }
    
    @discardableResult
    public func id(_ id: String)  -> Self {
        addAttribute(.id(id))
        return self
    }
    
    @discardableResult
    public func name(_ name: String)  -> Self {
        // remove existing name etries to stop duplication
        attributes.removeAll(where: { if case .name(_) = $0 { return true } else { return false } })
        addAttribute(.name(name))
        return self
    }
    
    @discardableResult
    public func label(_ text: String)  -> Self {
        
        // remove existing name etries to stop duplication
        attributes.removeAll(where: { if case .label(_) = $0 { return true } else { return false } })
        addAttribute(.label(text))
        return self
        
    }
    
    @discardableResult
    public func value(_ value: String)  -> Self {
        addAttribute(.value(value))
        return self
    }
    
    @discardableResult
    public func innerHTML(_ value: String)  -> Self {
        addAttribute(.innerHTML(value))
        return self
    }
    
    @discardableResult
    public func type(_ type: String)  -> Self {
        // remove existing type etries to stop duplication
        attributes.removeAll(where: { if case .type(_) = $0 { return true } else { return false } })
        addAttribute(.type(type))
        return self
    }
    
    @discardableResult
    public func placeholder(_ placeholder: String)  -> Self {
        addAttribute(.placeholder(placeholder))
        return self
    }
    
    @discardableResult
    public func required()  -> Self {
        addAttribute(.required)
        return self
    }
    
    @discardableResult
    public func disabled()  -> Self {
        addAttribute(.disabled)
        return self
    }
    
    @discardableResult
    public func readonly()  -> Self {
        addAttribute(.readonly)
        return self
    }
    
    @discardableResult
    public func checked()  -> Self {
        addAttribute(.checked)
        return self
    }
    
    @discardableResult
    public func selected()  -> Self {
        addAttribute(.selected)
        return self
    }
    
    @discardableResult
    public func src(_ src: String)  -> Self {
        addAttribute(.src(src))
        return self
    }
    
    @discardableResult
    public func href(_ href: String)  -> Self {
        addAttribute(.href(href))
        return self
    }
    
    @discardableResult
    public func alt(_ alt: String)  -> Self {
        addAttribute(.alt(alt))
        return self
    }
    
    @discardableResult
    public func title(_ title: String)  -> Self {
        addAttribute(.title(title))
        return self
    }
    
    @discardableResult
    public func style(_ style: String)  -> Self {
        addAttribute(.style(style))
        return self
    }
    
    @discardableResult
    public func script(_ script: String)  -> Self {
        addAttribute(.script(script))
        return self
    }
    
    @discardableResult
    public func data(_ data: String)  -> Self {
        addAttribute(.data(data))
        return self
    }
    
    @discardableResult
    public func custom(_ custom: String)  -> Self {
        addAttribute(.custom(custom))
        return self
    }
    
    /// hides the button via class and attribute
    @discardableResult
    public func hidden(_ hidden: Bool = false) -> Self {
        if hidden {
            addAttribute(.class("visually-hidden"))
        }
        return self
    }
    
    /// hides the button via class and attribute
    @discardableResult
    public func hidden(_ hidden: WebVariableElement) -> Self {
        addAttribute(.script("""
            function updateVariable\(builderId)(value) {
                if (value) {
                    \(builderId).classList.add("visually-hidden");
                } else {
                    \(builderId).classList.remove("visually-hidden");
                }
            }
            addCallback\(hidden.builderId)(updateVariable\(builderId));
            """))
        if hidden.asBool() {
            addAttribute(.class("visually-hidden"))
        }
        return self
    }
    
    /// hides the button via class and attribute
    @discardableResult
    public func disabled(_ disabled: WebVariableElement) -> Self {
        addAttribute(.script("""
            function updateVariable\(builderId)(value) {
                if (value) {
                    \(builderId).classList.add("disabled");
                } else {
                    \(builderId).classList.remove("disabled");
                }
            }
            addCallback\(disabled.builderId)(updateVariable\(builderId));
            """))
        if disabled.asBool() {
            addAttribute(.class("disabled"))
        }
        return self
    }
    
    @discardableResult
    public func required(_ reqd: Bool = false) -> Self {
        if reqd {
            addAttribute(.custom("required"))
        }
        return self
    }
    
    @discardableResult
    public func validate(_ conditions: [ValidationCondition]) -> Self {
        // so we will generate js to check the validation status of the element, we will not allow form submission
        for condition in conditions {
            addAttribute(.validation(condition))
        }
        return self
    }
    
}

public protocol WebEndpoint {
    
    var data: WebData { get set }
    var request: HttpRequest { get set }
    var controller: String? { get set }
    var method: String? { get set }
    var authenticationRequired: [WebAuthenticationStatus] { get set }
    func create() -> Self
    static func path(action: WebRequestActivity?, resource: UUID?, subResource: UUID?, version: UUID?, filter: [String: String]?, fragment: String?, returnUrl: String?) -> String
    var ephemeralData: [String : Any?] { get set }
    var authenticationIdentifier: String? { get set }
    
}

public extension WebEndpoint {
    
    static func path(
        action: WebRequestActivity? = nil,
        resource: UUID? = nil,
        subResource: UUID? = nil,
        version: UUID? = nil,
        filter: [String: String]? = nil,
        fragment: String? = nil,
        returnUrl: String? = nil) -> String {
        
        var path = "/"
        
        if let this = self as? WebEndpoint {
            if let controller = this.controller {
                path += "\(controller)"
            }
            
            if let method = this.method {
                path += "/\(method)"
            }
        }
        
        // check if there are any params at all and if so, append a "?"
        if action != nil || resource != nil || subResource != nil || version != nil || filter != nil || fragment != nil || returnUrl != nil {
            path += "?"
        }
        
        if let action = action {
            path += "action=\(action.rawValue)"
        }
        
        if let resource = resource {
            path += "&resource=\(resource)"
        }
        
        if let subResource = subResource {
            path += "&subResource=\(subResource)"
        }
        
        if let version = version {
            path += "&version=\(version)"
        }
        
        if let filter = filter {
            path += "&filter="
            // now encode the filter as a JSON string
            if let data = try? JSONSerialization.data(withJSONObject: filter, options: .prettyPrinted) {
                if let jsonString = String(data: data, encoding: .utf8) {
                    // now append but make sure the string is URL encoded
                    path += "\(jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                }
            }
        }
        
        return path
        
    }
    
    var path: String {
        get {
            var path = "/"
            if let controller = self.controller {
                path += "\(controller)"
            }
            if let method = self.method {
                path += "/\(method)"
            }
            return path
        }
    }
    
}

public protocol WebContent {
    
    // default calls for events
    func content() -> Any?
    func view() -> Any?
    func delete() -> Any?
    func modify() -> Any?
    func save() -> Any?
    func new() -> Any?
    func raw() -> Any?
    func redirect(_ path: String) -> HttpResponse
    func authenticateSession(token: String, expiry: Date?)
    func deauthenticateSession()
    func acceptedRoles(for action: WebRequestActivity) -> [String]?
    
}

public protocol WebApiEndpoint {
    func call() -> Any?
    func acceptedRoles() -> [String]?
}

internal extension [WebElement] {
    mutating func push(_ element: WebElement, _ closure: (() -> Void)) {
        self.append(element)
        closure()
        self.removeAll(where: { $0.builderId == element.builderId })
    }
}

internal extension CoreWebEndpoint {
    func updateWithEphermeralData(_ value: WebVariableElement) {
        
        guard let name = value.internalName else {
            return
        }
        
        if let previousValue = ephemeralData["previous_\(name)"] {
            if let v = previousValue {
                value.addAttribute(.initialValue(v))
            }
        }
        
        if let errorMessage = ephemeralData ["error_\(name)"] as? String {
            value.errorMessage = errorMessage
        } else {
            value.errorMessage = nil
        }
        
    }
}

open class CoreWebEndpoint {
    
    // create a new object and return it
    public func create() -> Self {
        return Self.init()
    }
    
    public required init() {}
    
    public var data: WebData = WebData()
    public var request: HttpRequest = HttpRequest()
    
    // session data
    public var ephemeralData: [String : Any?] = [:]
    public var authenticationIdentifier: String? = nil
    internal var newAuthenticationIdentifier: String? = nil
    internal var sessionExpiry: Date? = nil
    internal var headAttributes: [WebCoreHeadElement] = []
    
    public func redirect(_ path: String) -> HttpResponse {
        return HttpResponse.redirect(path, newAuthenticationIdentifier ?? authenticationIdentifier)
    }
    
    public func authenticateSession(token: String, expiry: Date? = nil) {
        newAuthenticationIdentifier = token
    }
    
    public func deauthenticateSession() {
        newAuthenticationIdentifier = nil
    }
    
    // data for final object construction
    internal var title: String? = nil
    internal var head: [HeadItem] = []
    internal var builderScripts: [String] = []
    internal var webRootElement: WebElement? = nil
    internal var stack: [WebElement] = []
    internal var domLoadedScripts: [String] = []
    
    // default content methods
    open func content() -> Any? {
        return HttpResponse.notFound
    }
    
    open func view() -> Any? {
        return HttpResponse.notFound
    }
    
    open func delete() -> Any? {
        return HttpResponse.notFound
    }
    
    open func modify() -> Any? {
        return HttpResponse.notFound
    }
    
    open func save() -> Any? {
        return HttpResponse.notFound
    }
    
    open func new() -> Any? {
        return HttpResponse.notFound
    }
    
    open func raw() -> Any? {
        return HttpResponse.notFound
    }
    
}

class Test : CoreWebEndpoint, WebEndpoint, WebContent {

    public required init() {
        super.init()
    }
    
    var controller: String? = "test"
    
    var method: String? = nil
    
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]
    
    override func content() -> Any? {
        return HttpResponse.ok(.text("hello, test"), nil)
    }
      
    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
    
}
