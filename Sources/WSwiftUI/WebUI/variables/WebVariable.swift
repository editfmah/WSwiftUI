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

public class WebVariableElement : WebElement {
    
    internal var variableType: WebVariableType = .bool
    internal var internalName: String? = nil
    internal var errorMessage: String? = nil
    
    private var initial: Any? = nil
    
    @discardableResult
    internal func asJSValue() -> String {
        switch variableType {
        case .bool:
            return asBool() ? "true" : "false"
        case .int:
            return String(asInt())
        case .double:
            return String(asDouble())
        case .string:
            return "'\(asString())'"
        case .array:
            let array = asArray().map { "'\($0)'" }.joined(separator: ",")
            return "[\(array)]"
        case .object:
            // Assuming object is a dictionary of String: Any
            if let dict = initial as? [String: Any] {
                let entries = dict.map { "'\($0.key)': '\($0.value)'" }.joined(separator: ",")
                return "{\(entries)}"
            }
            return "{}"
        }
    }
    
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
    override public func name(_ name: String) -> Self {
        addAttribute(.name(name))
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
        
        // on page load, set the initial value of the variable
        document.addEventListener('DOMContentLoaded', function() {
            updateWebVariable\(builderId)(\(asJSValue());
        });
        
        """))
    }
    
    @discardableResult
    public func liveUpdate(
        url: String,
        reference: String,
        actions: [WebVariableLiveUpdateActions] = [.read],
        related: [WebVariableElement]? = nil,
        onRequest: [WebAction]? = nil,
        onResponse: [WebAction]? = nil
    ) -> Self {
        return liveUpdate(url: url,
                          reference: reference,
                          actions: actions,
                          related: related,
                          onRequest: onRequest,
                          onResponse: onResponse,
                          pollEverySeconds: nil)
    }

    @discardableResult
    public func liveUpdate(
        url: String,
        reference: String,
        actions: [WebVariableLiveUpdateActions] = [.read],
        related: [WebVariableElement]? = nil,
        onRequest: [WebAction]? = nil,
        onResponse: [WebAction]? = nil,
        pollEverySeconds: Int?
    ) -> Self {

        let nameSelf = internalName ?? builderId

        func typeString(_ t: WebVariableType) -> String {
            switch t {
            case .bool:   return "bool"
            case .int:    return "int"
            case .double: return "double"
            case .string: return "string"
            case .array:  return "array"
            case .object: return "object"
            }
        }

        // Client-side descriptors (not sent)
        let selfEntry = "{name:'\(nameSelf)',id:'\(builderId)',type:'\(typeString(variableType))'}"
        let relatedEntries = (related ?? []).map {
            let n = $0.internalName ?? $0.builderId
            return "{name:'\(n)',id:'\($0.builderId)',type:'\(typeString($0.variableType))'}"
        }.joined(separator: ",")

        let varsArrayJS = "[\(selfEntry)\(relatedEntries.isEmpty ? "" : ",\(relatedEntries)")]"

        // internalName -> builderId for applying server responses
        let nameToIdMapJS: String = {
            var pairs = ["'\(nameSelf)':'\(builderId)'"]
            if let r = related {
                pairs.append(contentsOf: r.map { "'\($0.internalName ?? $0.builderId)':'\($0.builderId)'" })
            }
            return "{\(pairs.joined(separator: ","))}"
        }()

        let allowRead  = actions.contains(.read)
        let allowWrite = actions.contains(.write)

        let onRequestJS  = onRequest.map { CompileActions($0, builderId: builderId) } ?? ""
        let onResponseJS = onResponse.map { CompileActions($0, builderId: builderId) } ?? ""
        let pollJS       = pollEverySeconds.map { String(max(0, $0)) } ?? "0"

        addAttribute(.script("""
        (function(){
            var vars_\(builderId) = \(varsArrayJS);
            var nameToId_\(builderId) = \(nameToIdMapJS);

            // Prevent feedback loops when applying server responses
            var isApplying_\(builderId) = false;

            // Polling (fixed interval, seconds)
            var pollEverySec_\(builderId) = \(pollJS);
            var pollTimer_\(builderId) = null;
            var readInFlight_\(builderId) = false;

            // Skip the very first callback each var fires (from DOMContentLoaded init)
            var skippedFirst_\(builderId) = {};
            for (var i=0;i<vars_\(builderId).length;i++){ skippedFirst_\(builderId)[vars_\(builderId)[i].id] = false; }

            function collectData_\(builderId)(){
                var d = {};
                for (var i=0; i<vars_\(builderId).length; i++){
                    var v = vars_\(builderId)[i];
                    try { d[v.name] = window[v.id]; } catch(_){ d[v.name] = undefined; }
                }
                return d;
            }

            function buildPayload_\(builderId)(doRead, doWrite){
                var payload = {
                    reference: "\(reference)",
                    read: !!doRead,
                    write: !!doWrite,
                    data: {}
                };
                var curr = collectData_\(builderId)();
                for (var n in curr) if (Object.prototype.hasOwnProperty.call(curr, n)) {
                    payload.data[n] = curr[n]; // raw JS var values
                }
                return payload;
            }

            function doFetch_\(builderId)(payload){
                return fetch("\(url)", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    credentials: "same-origin",
                    body: JSON.stringify(payload)
                }).then(function(r){
                    if(!r.ok) throw new Error('HTTP ' + r.status);
                    return r.json();
                });
            }

            function applyResponse_\(builderId)(resp){
                if (!resp || !resp.data) return;
                isApplying_\(builderId) = true;
                try {
                    for (var key in resp.data) if (Object.prototype.hasOwnProperty.call(resp.data, key)) {
                        var targetId = nameToId_\(builderId)[key];
                        if (!targetId) continue;
                        var val = resp.data[key];
                        // Use generated updater to keep hidden input + callbacks in sync
                        var fn = window['updateWebVariable' + targetId];
                        if (typeof fn === 'function') {
                            fn(val);
                        } else {
                            // Fallback (should rarely be needed)
                            try { window[targetId] = val; } catch(_){}
                            var hidden = document.getElementById('hiddenInput_' + targetId);
                            if (hidden) {
                                hidden.value = (Array.isArray(val) || (val && typeof val === 'object'))
                                    ? JSON.stringify(val)
                                    : String(val ?? '');
                            }
                        }
                    }
                } finally {
                    isApplying_\(builderId) = false;
                }
            }

            function send_\(builderId)(doRead, doWrite){
                if (!doRead && !doWrite) return Promise.resolve();
                \(onRequestJS)
                return doFetch_\(builderId)(buildPayload_\(builderId)(doRead, doWrite))
                    .then(applyResponse_\(builderId))
                    .catch(function(e){ console && console.warn && console.warn(e); })
                    .finally(function(){ \(onResponseJS) });
            }

            // Register callbacks: on any callback (after first), push WRITE (no READ)
            (function(){
                for (var i=0; i<vars_\(builderId).length; i++){
                    (function(v){
                        var addCb = window['addCallback' + v.id];
                        if (typeof addCb === 'function') {
                            addCb(function(_newVal){
                                if (!\(allowWrite ? "true" : "false")) return;
                                if (isApplying_\(builderId)) return; // ignore our own updates from server
                                if (skippedFirst_\(builderId)[v.id] === false) {
                                    // first callback for this var is the DOMContentLoaded init — ignore it
                                    skippedFirst_\(builderId)[v.id] = true;
                                    return;
                                }
                                // Write current values for all involved vars; no read
                                send_\(builderId)(false, true);
                            });
                        }
                    })(vars_\(builderId)[i]);
                }
            })();

            // Polling reads at fixed interval; no initial read
            function startPolling_\(builderId)(){
                if (!\(allowRead ? "true" : "false")) return;
                if (!pollEverySec_\(builderId) || pollEverySec_\(builderId) <= 0) return;
                if (pollTimer_\(builderId)) { try { clearInterval(pollTimer_\(builderId)); } catch(_){ } }
                pollTimer_\(builderId) = setInterval(function(){
                    if (readInFlight_\(builderId)) return;
                    readInFlight_\(builderId) = true;
                    send_\(builderId)(true, false)
                        .finally(function(){ readInFlight_\(builderId) = false; });
                }, pollEverySec_\(builderId) * 1000);
            }

            document.addEventListener('DOMContentLoaded', function(){
                // DO NOT write initially; just begin polling if configured.
                startPolling_\(builderId)();
            });

            // Manual hooks if needed
            window['liveWrite_\(builderId)'] = function(){ return send_\(builderId)(false, true); };
            window['liveRead_\(builderId)']  = function(){ return send_\(builderId)(\(allowRead ? "true" : "false"), false); };
            window['liveSync_\(builderId)']  = function(){ return send_\(builderId)(\(allowRead ? "true" : "false"), \(allowWrite ? "true" : "false")); };
        })();
        """))

        return self
    }


    
}

public enum WebVariableLiveUpdateActions {
    case write
    case read
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
