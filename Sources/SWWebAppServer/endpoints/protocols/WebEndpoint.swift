//
//  WebEndpoint.swift
//  SwiftUIWebServer
//
//  Created by Adrian on 29/01/2025.
//

import Foundation

public protocol WebEndpoint {
    
    // static properties of the endpoint class
    static var controller: String? { get }
    static var method: String? { get }
    static var authenticationRequired: Bool { get }
    
    // navigation properties
    static func path(action: WebAction?, resource: UUID?, subResource: UUID?, version: UUID?, filter: [String: String]?, fragment: String?, returnUrl: String?) -> String
    
}

