//
//  Picker.swift
//  SWWebAppServer
//
//  Created by Adrian on 07/07/2025.
//

import Foundation

public enum WebPickerType {
    case combo
    case segmented
    case radio
    case colorPicker
    case menu
}

// 1) Dedicated subclasses for Picker (dropdown) and its parts
public class WebPickerElement: WebCoreElement {
    var value: WebVariableElement? = nil
    var type: WebPickerType = .combo
}

// 7) DSL on BaseWebEndpoint
public extension CoreWebEndpoint {
    // Internal creators
    fileprivate func createPicker(_ init: (WebPickerElement) -> Void) -> WebPickerElement {
        let el = WebPickerElement()
        populateCreatedObject(el)
        `init`(el)
        return el
    }
    
    /*
     
     <select class="form-select" aria-label="Default select example">
     <option selected>Open this select menu</option>
     <option value="1">One</option>
     <option value="2">Two</option>
     <option value="3">Three</option>
     </select>
     
     */
    
    /// Main Picker container (dropdown)
    @discardableResult
    func Picker(type: WebPickerType,
                binding: WebVariableElement? = nil,
                _ content: WebComposerClosure)
    -> WebPickerElement {
        switch type {
            case .combo:
                let picker = createPicker { el in
                    el.elementName = "select"
                    el.class("form-select")
                    el.value = binding
                    el.type = type
                    if let binding {
                        el.addAttribute(.custom("onChange=\"updateWebVariable\(binding.builderId)(this.value);\""))
                    }
                }
                stack.append(picker)
                // items go here
                content()
                // pop menu and picker
                stack.removeAll(where: { $0.builderId == picker.builderId })
                if let binding {
                    picker.addAttribute(.script("\(binding.builderId) = \(picker.builderId).value;"))
                }
                // if there is a binding, generate javascript to read the current value from the binding and select the current
                
                return picker
            case .segmented:
                break;
            case .radio:
                // basically, we do nothing as a radio is all controlled from it's parents id
                let picker = createPicker { el in
                    el.elementName = "div"
                    el.value = binding
                    el.type = type
                }
                stack.append(picker)
                // items go here
                content()
                // pop menu and picker
                stack.removeAll(where: { $0.builderId == picker.builderId })
                return picker
            case .colorPicker:
                break;
            case .menu:
                break;
        }
        
        return WebPickerElement()
        
    }
    
}
