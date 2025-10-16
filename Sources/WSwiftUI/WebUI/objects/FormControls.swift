//
//  FormControls.swift
//  SWWebAppServer
//
//  Created by Adrian on 08/07/2025.
//

import Foundation

// 1) Subclasses for form elements
public class WebFormGroupElement: WebElement {}
public class WebLabelElement: WebElement {}
public class WebInputElement: WebElement {}
public class WebTextAreaElement: WebElement {}
public class WebSelectElement: WebElement {}
public class WebOptionElement: WebElement {}

// 2) Input types
public enum InputType: String {
    case text, password, email, url, tel, search, number
}

// 3) Fluent modifiers
public extension WebLabelElement {
    @discardableResult
    func `for`(_ id: String) -> Self {
        addAttribute(.pair("for", id))
        return self
    }
    @discardableResult
    func textAlign(_ align: String) -> Self {
        addAttribute(.class("text-\(align)"))
        return self
    }
}

public extension WebInputElement {
    @discardableResult
    func type(_ t: InputType) -> Self {
        addAttribute(.pair("type", t.rawValue))
        return self
    }
    @discardableResult
    func disabled(_ on: Bool = true) -> Self {
        if on { addAttribute(.pair("disabled","")) }
        return self
    }
    @discardableResult
    func readonly(_ on: Bool = true) -> Self {
        if on { addAttribute(.pair("readonly","")) }
        return self
    }
}

public extension WebTextAreaElement {
    @discardableResult
    func rows(_ cnt: Int) -> Self {
        addAttribute(.pair("rows","\(cnt)"))
        return self
    }
    @discardableResult
    func cols(_ cnt: Int) -> Self {
        addAttribute(.pair("cols","\(cnt)"))
        return self
    }
    @discardableResult
    func disabled(_ on: Bool = true) -> Self {
        if on { addAttribute(.pair("disabled","")) }
        return self
    }
    @discardableResult
    func readonly(_ on: Bool = true) -> Self {
        if on { addAttribute(.pair("readonly","")) }
        return self
    }
}

public extension WebSelectElement {
    @discardableResult
    func multiple(_ on: Bool = true) -> Self {
        if on { addAttribute(.pair("multiple","")) }
        return self
    }
    @discardableResult
    func size(_ cnt: Int) -> Self {
        addAttribute(.pair("size","\(cnt)"))
        return self
    }
    @discardableResult
    func disabled(_ on: Bool = true) -> Self {
        if on { addAttribute(.pair("disabled","")) }
        return self
    }
}

public extension WebOptionElement {
    @discardableResult
    func selected(_ on: Bool = true) -> Self {
        if on { addAttribute(.pair("selected","")) }
        return self
    }
    @discardableResult
    func disabled(_ on: Bool = true) -> Self {
        if on { addAttribute(.pair("disabled","")) }
        return self
    }
}

// 4) DSL factories
public extension CoreWebEndpoint {

    /// Bound <input> element
    @discardableResult
    func TextField(binding: WebVariableElement,
               type: InputType = .text)
    -> WebInputElement {
        
        // update with previous session data
        updateWithEphermeralData(binding)

        let inp = WebInputElement()
        populateCreatedObject(inp)
        inp.elementName = "input"
        inp.type(type)
        inp.class("form-control")
        if binding.errorMessage != nil {
            inp.addAttribute(.errorMessage(binding.errorMessage!))
        }
        let id = "\(inp.builderId)"
        inp.id(id)
        if let varName = binding.internalName { inp.name(varName) }
        inp.value(binding.asString())
        inp.addAttribute(.script("""
function updateVariable\(inp.builderId)(value) {
    \(inp.builderId).value = value;
}
addCallback\(binding.builderId)(updateVariable\(inp.builderId));
"""))
        inp.addAttribute(.custom("onChange=\"updateWebVariable\(binding.builderId)(this.value);\""))
        return inp
    }

    /// Bound <textarea>
    @discardableResult
    func TextArea(value: WebVariableElement)
    -> WebTextAreaElement {
        
        // update with previous session data
        updateWithEphermeralData(value)
        
        let ta = WebTextAreaElement()
        populateCreatedObject(ta)
        ta.elementName = "textarea"
        if value.errorMessage != nil {
            ta.addAttribute(.errorMessage(value.errorMessage!))
        }
        if let varName = value.internalName { ta.name(varName) }
        ta.class("form-control")
        let id = "\(ta.builderId)"
        ta.id(id)
        ta.addAttribute(.script("""
function updateVariable\(ta.builderId)(value) {
    \(ta.builderId).value = value;
}
addCallback\(value.builderId)(updateVariable\(ta.builderId));
"""))
        ta.addAttribute(.custom("onChange=\"updateWebVariable\(value.builderId)(this.value);\""))
        return ta
    }

}
