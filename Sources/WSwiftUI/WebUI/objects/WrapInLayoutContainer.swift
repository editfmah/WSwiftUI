//
//  WrapInLayoutContainer.swift
//  SWWebAppServer
//
//  Created by Adrian on 16/07/2025.
//

public extension CoreWebEndpoint {
    
    @discardableResult
    func WrapInLayoutContainer(_ closure: WebComposerClosure) -> Any {
        if parent?.layout == .horizontal {
            return VStack {
                let object = create { element in
                    element.class("col")
                }
                stack.append(object)
                closure()
                stack.removeAll(where: { $0.builderId == object.builderId })
            }
        } else if parent?.layout == .vertical {
            return VStack {
                let object = create { element in
                    element.class("row")
                }
                stack.append(object)
                closure()
                stack.removeAll(where: { $0.builderId == object.builderId })
            }
        } else {
            let object = create { element in
                element.class("row")
            }
            stack.append(object)
            closure()
            stack.removeAll(where: { $0.builderId == object.builderId })
            return object
        }
    }
    
}
