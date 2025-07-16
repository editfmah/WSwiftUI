//
//  Text.swift
//  SWWebAppServer
//
//  Created by Adrian on 01/07/2025.
//

public extension BaseWebEndpoint {
    
    // MARK: – Plain text
    @discardableResult
    func Text(_ text: String) -> WebCoreElement {
        var result: WebCoreElement?
        
        WrapInLayoutContainer {
            // if we’re inside a picker, branch on its type…
            if let parent = parent, parent.isPicker(), let type = parent.pickerType() {
                switch type {
                case .dropdown:
                    result = create { element in
                        element.elementName  = "option"
                        element.class("text")
                        element.innerHTML(text)
                        element.class("col")
                    }
                case .segmented:
                    result = create { element in
                        element.elementName  = "button"
                        element.class("\(element.builderId) btn btn-secondary text")
                        element.innerHTML(text)
                        // the <button> needs a "button" type
                        element.script("\(element.builderId).type = 'button';")
                        element.class("col")
                    }
                default:
                    break
                }
            }
            // default (no picker)
            result = create { element in
                element.elementName  = "span"
                element.class("text")
                element.innerHTML(text)
                element.class("col")
                
            }
        }
        
        return result!
        
    }
    
    
    // MARK: – WString binding
    @discardableResult
    func Text(_ binding: WebVariableElement) -> WebCoreElement {
        
        var result: WebCoreElement?
        
        WrapInLayoutContainer {
            result = create { element in
                element.elementName = "span"
                element.class(element.builderId)
                
                // initial value
                element.script("""
            \(element.builderId).innerText = '\(binding.asString())');
            """)
                
                // poll for updates
                element.script("""
            l\(element.builderId)();
            function l\(element.builderId)() {
              const rl = () => {
                \(element.builderId).innerText = \(binding.builderId);
                return setTimeout(rl, 500);
              };
              rl();
            }
            """)
                
                element.class("col")
            }
        }
        return result!
    }
    
}
