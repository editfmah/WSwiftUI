//
//  Toggle.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 09/08/2025.
//

import Foundation

public extension CoreWebEndpoint {
    
    // MARK: – WBool binding
    @discardableResult
    func Toggle(value: WebVariableElement) -> WebElement {
        
        var result: WebElement?
        
        /*
         
         <div class="form-check">
           <input class="form-check-input" type="radio" name="exampleRadios" id="exampleRadios1" value="option1" checked>
           <label class="form-check-label" for="exampleRadios1">
             Default radio
           </label>
         </div>
         
         */
        
        WrapInLayoutContainer {
            let outerDiv = create { element in
                
                element.elementName = "div"
                element.class(element.builderId)
                element.class("form-check")
                element.class("wsui-toggle")
                
            }
            
            // push div onto stack
            stack.append(outerDiv)
            
            // generate the input
            result = create { element in
                
                element.elementName = "input"
                element.class("form-check-input")
                element.type("checkbox")
                element.id("\(element.builderId)")
                if let varName = value.internalName { element.name(varName) }
                
                element.addAttribute(.custom("onChange=\"updateWebVariable\(value.builderId)(this.checked);\""))
                
                // initial value
                if value.asBool() {
                    element.checked()
                }
                
                // register callbacks for updates to the bound variable
                element.script("""
                    function updateVariable\(element.builderId)(value) {
                        var isChecked = (value === true || value === 'true' || value === 1 || value === '1');

                        // Update the checkbox state
                        \(element.builderId).checked = isChecked;

                        // (Optional) keep the attribute in sync for SSR/HTML snapshots
                        if (isChecked) {
                            \(element.builderId).setAttribute('checked', 'checked');
                        } else {
                            \(element.builderId).removeAttribute('checked');
                        }
                    }
                    addCallback\(value.builderId)(updateVariable\(element.builderId));
                """)
                
            }
            
            // pop div
            stack.removeAll(where: { $0.builderId == outerDiv.builderId })
            
        }
        return result!
    }
    
}
