//
//  MenuIndexable.swift
//  SWWebAppServer
//
//  Created by Adrian on 31/01/2025.
//

public protocol MenuIndexable {
    var menuPrimary: String { get }
    var menuSecondary: String? { get }
    var itemVisibility: [WebAuthenticationStatus] { get }
}
