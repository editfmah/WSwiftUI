//
//  File.swift
//
//
//  Created by Adrian Herridge on 18/02/2024.
//

import Foundation

public extension CoreWebEndpoint {
    
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
    internal func createWebVariableFunctions() -> Self {
        // create the functions to get/set this variable
        addAttribute(.script("""
        
        // array of callback functions that take a single value parameter
        var callbacks\(builderId) = [];
        
        function addCallback\(builderId)(callback) {
            // add a callback function to the array
            callbacks\(builderId).push(callback);
        }
        
        // create monitor and variable functions for updates and monitoring
        function updateHiddenInput\(builderId)(value) {
            document.getElementById('hiddenInput_\(builderId)').value = value;
            \(builderId) = value;
        }
        
        // var updates the hidden input as well as var. Then notifies a change to the bound objects
        function updateWebVariable\(builderId)(value) {
            // check to see if the value has actually changed before kicking off callbacks
            \(builderId) = value;
            updateHiddenInput\(builderId)(value);
        
            // loop through the callbacks and call them with the new value
            for (var i = 0; i < callbacks\(builderId).length; i++) {
                callbacks\(builderId)[i](value);
            }
        }
        
        """))
    }
    
}

public extension CoreWebEndpoint {
    
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
            element.createWebVariableFunctions()
            
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
            element.createWebVariableFunctions()
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
            element.createWebVariableFunctions()
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
            element.addAttribute(.name(element.builderId))
            element.addAttribute(.type("hidden"))
            element.addAttribute(.script("var \(element.builderId) = '\(value)';"))
            element.setInitialValue(value)
            element.addAttribute(.value(value))
            
            // observer to keep hidden field in sync
            element.createWebVariableFunctions()
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
            element.createWebVariableFunctions()
        }
        
        return object
        
    }
    
}
