//
//  BaseWebEndpoint+HStack.swift
//  SWWebAppServer
//
//  Created by Adrian on 01/07/2025.
//

public extension BaseWebEndpoint {
    
    var parent: WebCoreElement? {
        get {
            return stack.last ?? webRootElement
        }
    }
    
    internal func populateCreatedObject(_ element: WebCoreElement) {
        
        element.class(element.builderId)
        
        // put this object within its parent
        if webRootElement == nil {
            webRootElement = element
        } else {
            // there is a heirarchy, so look at the stack
            if let parent = stack.last {
                parent.subElements.append(element)
            } else {
                webRootElement?.subElements.append(element)
            }
        }
        
    }
    
    func create(_ init: (_ element: WebCoreElement) -> Void) -> WebCoreElement {
        
        // work out if the parent 
        
        var element = WebCoreElement()
        
        populateCreatedObject(element)
        `init`(element)
        
        return element
    }
    
    
    
    
    
}
