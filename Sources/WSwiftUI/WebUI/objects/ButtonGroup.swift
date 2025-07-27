//
//  ButtonGroup.swift
//  SWWebAppServer
//
//  Created by Adrian on 06/07/2025.
//

import Foundation

// 1) Dedicated subclasses for ButtonGroup and ButtonGroupItem
public class WebButtonGroupElement: WebCoreElement {}
public class WebButtonGroupItemElement: WebCoreElement {}

// 2) Button group types
public enum ButtonGroupType: String {
    case radio
    case checkbox
}

// 3) Fluent methods for ButtonGroup behaviors
public extension WebButtonGroupElement {
    /// Apply Bootstrap classes for radio/checkbox toggle groups
    @discardableResult
    func type(_ type: ButtonGroupType) -> Self {
        addAttribute(.class("btn-group"))
        addAttribute(.class("btn-group-toggle"))
        addAttribute(.custom("data-toggle=\"buttons\""))
        return self
    }
    
    /// Stack buttons vertically
    @discardableResult
    func vertical() -> Self {
        addAttribute(.class("btn-group-vertical"))
        return self
    }
    
    /// CSS variable for selected-foreground color
    @discardableResult
    func selectedForeground(_ color: WebColor) -> Self {
        addAttribute(.style("--btn-selected-fg: \(color.rgba);"))
        return self
    }
    
    /// CSS variable for selected-background color
    @discardableResult
    func selectedBackground(_ color: WebColor) -> Self {
        addAttribute(.style("--btn-selected-bg: \(color.rgba);"))
        return self
    }
}

public extension WebButtonGroupElement {
    /// Bind the group to a WebVariableElement ([String]) by:
    ///  • defining grp.values  → JS array
    ///  • defining grp.value   → JSON string
    ///  • syncing clicks → values → UI
    ///  • initializing inputs from the binding’s default array
    @discardableResult
    func bindValues(_ binding: WebVariableElement, type: ButtonGroupType) -> Self {
        // the script below runs once, after your <label>+<input> items are in the DOM
        let script = """
    (function(){
      var grp = document.getElementById('\(builderId)');
      // Helper: update all <input> and <label> to match the passed-in array
      function updateUI(arr){
        grp.querySelectorAll('label').forEach(function(lbl){
          var inp = document.getElementById(lbl.htmlFor);
          var sel = inp && arr.indexOf(inp.value) > -1;
          if (inp) inp.checked = sel;
          lbl.classList.toggle('active', sel);
          if(sel){
            lbl.style.color = getComputedStyle(grp).getPropertyValue('--btn-selected-fg');
            lbl.style.backgroundColor = getComputedStyle(grp).getPropertyValue('--btn-selected-bg');
          } else {
            lbl.style.color = '';
            lbl.style.backgroundColor = '';
          }
        });
      }
    
      // 1) define .values as a real JS array property
      Object.defineProperty(grp, 'values', {
        get: function(){
          // read the window-bound model
          return window['\(binding.builderId)'] || [];
        },
        set: function(arr){
          // write back into the window model
          window['\(binding.builderId)'] = arr;
          updateUI(arr);
        }
      });
    
      // 2) define .value as a JSON-string shortcut
      Object.defineProperty(grp, 'value', {
        get: function(){
          return JSON.stringify(this.values);
        },
        set: function(json){
          try {
            var arr = JSON.parse(json);
            this.values = arr;
          } catch(e){
            console.warn('Invalid JSON for grp.value:', json);
          }
        }
      });
    
      // 3) on any user click/change, recompute checked inputs → grp.values
      grp.addEventListener('change', function(){
        var selector = "input[type='\(type.rawValue)']:checked";
        var arr = Array.from(grp.querySelectorAll(selector)).map(function(i){ return i.value; });
        // for radio, keep only the last one
        if('\(type.rawValue)'==='radio') arr = arr.length ? [arr.pop()] : [];
        grp.values = arr;
      });
    
      // 4) initialize: read whatever default is already in window[bindingId]
      //    (or you can set defaults by doing grp.value='[...]' in your page HTML)
      updateUI(window['\(binding.builderId)'] || []);
    })();
    """
        addAttribute(.script(script))
        return self
    }
}


// 4) DSL on BaseWebEndpoint
public extension CoreWebEndpoint {
    fileprivate func createButtonGroup(_ init: (_ element: WebButtonGroupElement) -> Void) -> WebButtonGroupElement {
        let element = WebButtonGroupElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }
    
    fileprivate func createButtonGroupItem(_ init: (_ element: WebButtonGroupItemElement) -> Void) -> WebButtonGroupItemElement {
        let element = WebButtonGroupItemElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }
    
    @discardableResult
    func ButtonGroup(_ binding: WebVariableElement,
                     type: ButtonGroupType = .radio,
                    _ content: WebComposerClosure) -> WebButtonGroupElement {
        let group = createButtonGroup { el in
            el.elementName = "div"
            el.addAttribute(.pair("role","group"))
            el.setInternalType(.picker(type: type == .radio ? .radio : .check))
            el.id(el.builderId)
        }
        group.type(type)
        group.addAttribute(.style("--btn-type: \(type.rawValue);"))
        group.bindValues(binding, type: type)
        
        stack.append(group)
        content()
        stack.removeAll { $0.builderId == group.builderId }
        return group
    }
    
    
    /// Defines an item within a ButtonGroup
    @discardableResult
    func ButtonGroupItem(title: String, value: String) -> WebButtonGroupItemElement {
        guard let parent = stack.last as? WebButtonGroupElement else {
            fatalError("ButtonGroupItem must be used inside a ButtonGroup { ... } block")
        }
        let inputId = "\(parent.builderId)-item-\(UUID().uuidString.prefix(8))"
        let inputType = parent.pickerType() == .check ? "checkbox" : "radio"
        
        // input
        _ = createButtonGroupItem { el in
            el.elementName = "input"
            el.class("btn-check")
            el.type(inputType)
            el.addAttribute(.pair("id", inputId))
            el.addAttribute(.pair("name", parent.builderId))
            el.addAttribute(.pair("value", value))
        }
        // label
        let label = createButtonGroupItem { el in
            el.elementName = "label"
            el.class("btn btn-outline-primary")
            el.addAttribute(.pair("for", inputId))
            el.innerHTML(title)
        }
        return label
    }
}
