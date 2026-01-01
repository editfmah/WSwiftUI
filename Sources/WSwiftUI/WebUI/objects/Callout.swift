//
//  Callout.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 13/08/2025.
//

import Foundation

public extension CoreWebEndpoint {
    
    /// Main Picker container (dropdown)
    @discardableResult
    func Callout(_ type: BootstrapVariant, _ content: WebComposerClosure)
    -> WebElement {
        
        let callout = create { el in
            el.elementName = "div"
            el.class("p-3")
            el.class("wsui-callout")
            el.border(.leading, .custom(type.rgb), width: 4)
            el.border(.top, .lightgrey, width: 1)
            el.border(.bottom, .lightgrey, width: 1)
            el.border(.trailing, .lightgrey, width: 1)
        }
        stack.append(callout)
        // items go here
        content()
        // pop menu and picker
        stack.removeAll(where: { $0.builderId == callout.builderId })
        
        return callout
        
    }
    
}
