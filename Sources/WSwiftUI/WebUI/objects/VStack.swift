//
//  VStack.swift
//  SWWebAppServer
//
//  Created by Adrian on 01/07/2025.
//

public extension CoreWebEndpoint {
    
    @discardableResult
    func VStack(_ closure: WebComposerClosure) -> WebCoreElement {
        let object = create { element in
            element.class("col")
            element.layout = .vertical
        }
        stack.append(object)
        closure()
        stack.removeAll(where: { $0.builderId == object.builderId })
        return object
    }
    
}
