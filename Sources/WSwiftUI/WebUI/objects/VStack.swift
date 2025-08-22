//
//  VStack.swift
//  SWWebAppServer
//
//  Created by Adrian on 01/07/2025.
//

public enum VStackContentMode {
    case fit
    case fill
}

public extension CoreWebEndpoint {
    
    @discardableResult
    func VStack(mode: VStackContentMode = .fill, _ closure: WebComposerClosure) -> WebElement {
        let object = create { element in
            element.class("col")
            if mode == .fit {
                element.class("col-md-auto")
            }
            element.layout = .vertical
        }
        stack.append(object)
        closure()
        stack.removeAll(where: { $0.builderId == object.builderId })
        return object
    }
    
}
