//
//  Head.swift
//  SWWebAppServer
//
//  Created by Adrian on 04/07/2025.
//

public extension BaseWebEndpoint {
    
    @discardableResult
    func head(_ element: WebCoreHeadElement) {
        headAttributes.append(element)
    }
    
}
