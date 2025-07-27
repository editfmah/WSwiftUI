//
//  Html.swift
//  SWWebAppServer
//
//  Created by Adrian on 04/07/2025.
//

public extension CoreWebEndpoint {
    
    @discardableResult
    func webpage(_ closure: WebComposerClosure) -> WebCoreElement {
        let object = create { element in
            element.name("HTML")
            element.addAttribute(.pair("lang", "en"))
        }
        stack.append(object)
        closure()
        stack.removeAll(where: { $0.builderId == object.builderId })
        return object
    }
    
}
