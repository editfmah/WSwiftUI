//
//  BaseWebEndpoint.swift
//  SWWebAppServer
//
//  Created by Adrian on 31/01/2025.
//

import Foundation

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
}

public class WebCoreElement {
    
    private var attributes: [WebCoreElementAttribute] = []
    public var name: String = "div"
    public var subElements: [WebCoreElement] = []
    
    public func addAttribute(_ attribute: WebCoreElementAttribute) {
        attributes.append(attribute)
    }
    
    public func `class`(_ className: String) {
        addAttribute(.class(className))
    }
    
    public func id(_ id: String) {
        addAttribute(.id(id))
    }
    
    public func name(_ name: String) {
        addAttribute(.name(name))
    }
    
    public func value(_ value: String) {
        addAttribute(.value(value))
    }
    
    public func type(_ type: String) {
        addAttribute(.type(type))
    }
    
    public func placeholder(_ placeholder: String) {
        addAttribute(.placeholder(placeholder))
    }
    
    public func required() {
        addAttribute(.required)
    }
    
    public func disabled() {
        addAttribute(.disabled)
    }
    
    public func readonly() {
        addAttribute(.readonly)
    }
    
    public func checked() {
        addAttribute(.checked)
    }
    
    public func selected() {
        addAttribute(.selected)
    }
    
    public func src(_ src: String) {
        addAttribute(.src(src))
    }
    
    public func href(_ href: String) {
        addAttribute(.href(href))
    }
    
    public func alt(_ alt: String) {
        addAttribute(.alt(alt))
    }
    
    public func title(_ title: String) {
        addAttribute(.title(title))
    }
    
    public func style(_ style: String) {
        addAttribute(.style(style))
    }
    
    public func data(_ data: String) {
        addAttribute(.data(data))
    }
    
    public func custom(_ custom: String) {
        addAttribute(.custom(custom))
    }
    
}

public class BaseWebEndpoint {
    
    // create a new object and return it
    static func create() -> Self {
        return self.init()
    }
    
    required init() {}
    
    public var request: HttpRequest = HttpRequest()
    
    // session data
    private var ephemeralData: [String : Any?] = [:]
    private var authenticationIdentifier: String? = nil
    private var newAuthenticationIdentifier: String? = nil
    private var sessionExpiry: Date? = nil
    
    public func redirect(_ path: String) -> HttpResponse {
        return HttpResponse.redirect(path, authenticationIdentifier)
    }
    
    public func authenticateSession(token: String, expiry: Date? = nil) {
        newAuthenticationIdentifier = token
    }
    
    public func deauthenticateSession() {
        newAuthenticationIdentifier = nil
    }
    
    // data for final object construction
    private var title: String? = nil
    private var head: [HeadItem] = []
    private var builderScripts: [String] = []
    private var bodyBuilder: [WebCoreElement] = []
    
}

class Test : BaseWebEndpoint, WebEndpoint {
    
    static let controller: String? = "home"
    
    static let method: String? = nil
    
    static let authenticationRequired: Bool = false
    
}
