//
//  HStack.swift
//  SWWebAppServer
//
//  Created by Adrian on 01/07/2025.
//

public extension CoreWebEndpoint {
    
    @discardableResult
    func HStack(_ closure: WebComposerClosure) -> CoreWebContent {
        let object = create { element in
            element.class("row")
            element.layout = .horizontal
        }
        stack.append(object)
        closure()
        stack.removeAll(where: { $0.builderId == object.builderId })
        return object
    }
    
}
