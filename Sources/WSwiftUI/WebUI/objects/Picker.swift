//
//  Picker.swift
//  SWWebAppServer
//
//  Created by Adrian on 07/07/2025.
//

import Foundation

public enum PickerAlignment {
    case horizontal
    case vertical
}

public enum WebPickerType : Equatable {
    case combo
    case segmented(BootstrapVariant)
    case radio(PickerAlignment)
    case colorPicker
}

// 1) Dedicated subclasses for Picker (dropdown) and its parts
public class WebPickerElement: WebElement {
    
    var value: WebVariableElement? = nil
    var type: WebPickerType = .combo
    var variant: BootstrapVariant = .primary
    
    @discardableResult
    func variant(_ variant: BootstrapVariant) -> Self {
        self.variant = variant
        return self
    }
    
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
                binding: WebVariableElement,
                _ content: WebComposerClosure)
    -> WebPickerElement {
        
        // update with previous session data
        updateWithEphermeralData(binding)
        
        switch type {
            case .combo:
                let picker = createPicker { el in
                    el.elementName = "select"
                    el.class("form-select")
                    el.class("wsui-picker")
                    el.value = binding
                    if binding.errorMessage != nil {
                        el.addAttribute(.errorMessage(binding.errorMessage!))
                    }
                    el.type = type
                    el.addAttribute(.custom("onChange=\"updateWebVariable\(binding.builderId)(this.value);\""))
                    // register callbacks for updates to the bound variable
                    el.script("""
                        function updateVariable\(el.builderId)(value) {
                                \(el.builderId).value = value;
                        }
                        addCallback\(binding.builderId)(updateVariable\(el.builderId));
                    """)
                    if let binding = binding.internalName {
                        el.name(binding)
                    }
                }
                stack.append(picker)
                // items go here
                content()
                // pop menu and picker
                stack.removeAll(where: { $0.builderId == picker.builderId })
                picker.addAttribute(.script("\(binding.builderId) = \(picker.builderId).value;"))
                // if there is a binding, generate javascript to read the current value from the binding and select the current
                
                return picker
            case .segmented:
                let picker = createPicker { el in
                    el.elementName = "div"
                    el.class("btn-group")
                    el.class("btn-group-toggle")
                    el.addAttribute(.pair("role", "group"))
                    if binding.errorMessage != nil {
                        el.addAttribute(.errorMessage(binding.errorMessage!))
                    }
                    el.value = binding
                    el.type = type
                }
                stack.append(picker)
                // items go here
                content()
                // pop menu and picker
                stack.removeAll(where: { $0.builderId == picker.builderId })
                return picker
            case .radio:
                // basically, we do nothing as a radio is all controlled from it's parents id
                let picker = createPicker { el in
                    el.elementName = "div"
                    el.value = binding
                    if binding.errorMessage != nil {
                        el.addAttribute(.errorMessage(binding.errorMessage!))
                    }
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
        }
        
        return WebPickerElement()
        
    }
    
}
