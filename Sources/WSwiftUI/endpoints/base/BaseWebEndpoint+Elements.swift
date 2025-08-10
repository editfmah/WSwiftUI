//
//  BaseWebEndpoint+HStack.swift
//  SWWebAppServer
//
//  Created by Adrian on 01/07/2025.
//

public extension CoreWebEndpoint {
    
    var parent: CoreWebContent? {
        get {
            return stack.last ?? webRootElement
        }
    }
    
    internal func populateCreatedObject(_ element: CoreWebContent) {
        
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
    
    func create(_ init: (_ element: CoreWebContent) -> Void) -> CoreWebContent {
        
        // work out if the parent 
        
        let element = CoreWebContent()
        
        populateCreatedObject(element)
        `init`(element)
        
        return element
    }
    
    
    
    
    
}
