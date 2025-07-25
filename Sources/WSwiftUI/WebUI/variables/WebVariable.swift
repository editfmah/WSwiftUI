//
//  File.swift
//
//
//  Created by Adrian Herridge on 18/02/2024.
//

import Foundation

public extension BaseWebEndpoint {
    
    fileprivate func createVariable(_ init: (_ element: WebVariableElement) -> Void) -> WebVariableElement {
        
        let element = WebVariableElement()
        populateCreatedObject(element)
        `init`(element)
        return element
        
    }
    
}

internal enum WebVariableType {
    case bool
    case int
    case double
    case string
    case array
    case object
}

public class WebVariableElement : WebCoreElement {
    
    internal var variableType: WebVariableType = .bool
    internal var internalName: String? = nil
    
    private var initial: Any? = nil
    
    @discardableResult
    internal func asArray() -> [String] {
        return initial as? [String] ?? []
    }
    internal func asString() -> String {
        return initial as? String ?? ""
    }
    internal func asInt() -> Int {
        return initial as? Int ?? 0
    }
    internal func asDouble() -> Double {
        return initial as? Double ?? 0.0
    }
    internal func asBool() -> Bool {
        return initial as? Bool ?? false
    }
    
    internal func setInitialValue(_ value: Any?) {
        self.initial = value
    }
    
    @discardableResult
    public func setName(_ name: String) -> Self {
        // now find the hidden input by id
        addAttribute(.script("document.getElementById('hiddenInput_\(builderId)').name = '\(name)';"))
        internalName = name
        return self
    }
    
    @discardableResult
    public func onValueChange(_ actions: [WebAction]) -> Self {
        addAttribute(.script("""
var lastValue\(builderId) = \(builderId);
var valueObserverInterval\(builderId) = setInterval(function() {
  if (\(builderId) !== lastValue\(builderId)) {
    \(compileActions(actions))
    lastValue\(builderId) = \(builderId);
  }
}, 500);
"""))
        return self
    }
    
}

public extension BaseWebEndpoint {
    
    fileprivate func addInternalVarMonitor(_ element: WebVariableElement) {
        // observer to keep hidden field in sync
        element.addAttribute(.script("""
var lastValue\(element.builderId) = \(element.builderId);
var valueInterval\(element.builderId) = setInterval(function() {
  if (\(element.builderId) !== lastValue\(element.builderId)) {
    document.getElementById('hiddenInput_\(element.builderId)').value = \(element.builderId);
    lastValue\(element.builderId) = \(element.builderId);
  }
}, 500);
"""))
    }
    
    @discardableResult
    func WBool(_ value: Bool) -> WebVariableElement {
        
        let object = createVariable { element in
            element.variableType = .bool
            element.elementName = "input"
            element.class("hidden-input")
            element.id("hiddenInput_\(element.builderId)")
            element.addAttribute(.pair("name", element.builderId))
            element.addAttribute(.type("hidden"))
            element.addAttribute(.script("var \(element.builderId) = \(value ? "true" : "false");"))
            element.addAttribute(.value(value ? "true" : "false"))
            element.setInitialValue(value)
            
            // observer to keep hidden field in sync
            addInternalVarMonitor(element)
            
        }
        
        return object
        
    }
    
    @discardableResult
    func WInt(_ value: Int) -> WebVariableElement {
        
        let object = createVariable { element in
            element.variableType = .int
            element.elementName = "input"
            element.class("hidden-input")
            element.id("hiddenInput_\(element.builderId)")
            element.addAttribute(.pair("name", element.builderId))
            element.addAttribute(.type("hidden"))
            element.addAttribute(.script("var \(element.builderId) = \(value);"))
            element.setInitialValue(value)
            element.addAttribute(.value(String(value)))
            
            // observer to keep hidden field in sync
            addInternalVarMonitor(element)
        }
        
        return object
    }
    
    @discardableResult
    func WDouble(_ value: Double) -> WebVariableElement {
        
        let object = createVariable { element in
            element.variableType = .double
            element.elementName = "input"
            element.class("hidden-input")
            element.id("hiddenInput_\(element.builderId)")
            element.addAttribute(.pair("name", element.builderId))
            element.addAttribute(.type("hidden"))
            element.addAttribute(.script("var \(element.builderId) = \(value);"))
            element.setInitialValue(value)
            element.addAttribute(.value(String(value)))
            
            // observer to keep hidden field in sync
            addInternalVarMonitor(element)
        }
        
        return object
        
    }
    
    @discardableResult
    func WString(_ value: String) -> WebVariableElement {
        
        let object = createVariable { element in
            element.variableType = .string
            element.elementName = "input"
            element.class("hidden-input")
            element.id("hiddenInput_\(element.builderId)")
            element.addAttribute(.pair("name", element.builderId))
            element.addAttribute(.type("hidden"))
            element.addAttribute(.script("var \(element.builderId) = '\(value)';"))
            element.setInitialValue(value)
            element.addAttribute(.value(value))
            
            // observer to keep hidden field in sync
            addInternalVarMonitor(element)
        }
        
        return object
        
    }
    
    @discardableResult
    func WArray(_ values: [String]) -> WebVariableElement {
        
        let object = createVariable { element in
            element.variableType = .array
            element.elementName = "input"
            element.class("hidden-input")
            element.id("hiddenInput_\(element.builderId)")
            element.addAttribute(.pair("name", element.builderId))
            element.addAttribute(.type("hidden"))
            element.addAttribute(.script("var \(element.builderId) = [\(values.map { "'\($0)'" }.joined(separator: ","))];"))
            element.setInitialValue(values)
            element.addAttribute(.value("[\(values.map { "'\($0)'" }.joined(separator: ","))]"))
            
            // observer to keep hidden field in sync
            addInternalVarMonitor(element)
        }
        
        return object
        
    }
    
}
