//
//  FormControls.swift
//  SWWebAppServer
//
//  Created by Adrian on 08/07/2025.
//

import Foundation

// 1) Subclasses for form elements
public class WebFormGroupElement: WebCoreElement {}
public class WebLabelElement: WebCoreElement {}
public class WebInputElement: WebCoreElement {}
public class WebTextAreaElement: WebCoreElement {}
public class WebSelectElement: WebCoreElement {}
public class WebOptionElement: WebCoreElement {}

// 2) Input types
public enum InputType: String {
    case text, password, email, url, tel, search, number, range, date, month, week, time, datetimeLocal = "datetime-local", color, file, hidden, submit, reset, checkbox, radio
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
public extension BaseWebEndpoint {
    /// Wraps form controls (adds mb-3)
    @discardableResult
    func FormGroup(_ content: WebComposerClosure) -> WebFormGroupElement {
        let grp = WebFormGroupElement()
        populateCreatedObject(grp)
        grp.elementName = "div"
        grp.class("mb-3")
        stack.append(grp)
        content()
        stack.removeAll(where: { $0.builderId == grp.builderId })
        return grp
    }

    /// <label> element
    @discardableResult
    func Label(_ text: String, for id: String? = nil) -> WebLabelElement {
        let lbl = WebLabelElement()
        populateCreatedObject(lbl)
        lbl.elementName = "label"
        if let fid = id { lbl.addAttribute(.pair("for", fid)) }
        lbl.innerHTML(text)
        return lbl
    }

    /// Static <input> element
    @discardableResult
    func Input(type: InputType = .text,
               name: String? = nil,
               placeholder: String? = nil,
               value: String? = nil,
               disabled: Bool = false,
               readonly: Bool = false)
    -> WebInputElement {
        let inp = WebInputElement()
        populateCreatedObject(inp)
        inp.elementName = "input"
        inp.type(type)
        inp.class("form-control")
        if let n = name { inp.name(n) }
        if let p = placeholder { inp.placeholder(p) }
        if let v = value { inp.value(v) }
        if disabled { inp.disabled() }
        if readonly { inp.readonly() }
        return inp
    }

    /// Bound <input> element
    @discardableResult
    func Input(_ variable: WebVariableElement,
               type: InputType = .text,
               placeholder: String? = nil,
               disabled: Bool = false,
               readonly: Bool = false)
    -> WebInputElement {
        let inp = WebInputElement()
        populateCreatedObject(inp)
        inp.elementName = "input"
        inp.type(type)
        inp.class("form-control")
        let id = "input_\(inp.builderId)"
        inp.id(id)
        if let varName = variable.internalName { inp.name(varName) }
        inp.value(variable.asString())
        if let p = placeholder { inp.placeholder(p) }
        if disabled { inp.disabled() }
        if readonly { inp.readonly() }
        inp.addAttribute(.script("""
(function() {
  var el = document.getElementById('\(id)');
  var _lastVal = el.value;
  el.addEventListener('input', function(evt) {
    \(variable.builderId) = evt.target.value;
  });
  setInterval(function() {
    if (\(variable.builderId) !== _lastVal) {
      el.value = \(variable.builderId);
      _lastVal = \(variable.builderId);
    }
  }, 500);
})();
"""))
        return inp
    }

    /// Static <textarea>
    @discardableResult
    func TextArea(name: String? = nil,
                  rows: Int? = nil,
                  cols: Int? = nil,
                  placeholder: String? = nil,
                  value: String? = nil,
                  disabled: Bool = false,
                  readonly: Bool = false)
    -> WebTextAreaElement {
        let ta = WebTextAreaElement()
        populateCreatedObject(ta)
        ta.elementName = "textarea"
        ta.class("form-control")
        if let n = name { ta.name(n) }
        if let r = rows { ta.rows(r) }
        if let c = cols { ta.cols(c) }
        if let p = placeholder { ta.placeholder(p) }
        if let v = value { ta.innerHTML(v) }
        if disabled { ta.disabled() }
        if readonly { ta.readonly() }
        return ta
    }

    /// Bound <textarea>
    @discardableResult
    func TextArea(_ variable: WebVariableElement,
                  rows: Int? = nil,
                  cols: Int? = nil,
                  placeholder: String? = nil,
                  disabled: Bool = false,
                  readonly: Bool = false)
    -> WebTextAreaElement {
        let ta = WebTextAreaElement()
        populateCreatedObject(ta)
        ta.elementName = "textarea"
        ta.class("form-control")
        let id = "textarea_\(ta.builderId)"
        ta.id(id)
        if let n = variable.internalName { ta.name(n) }
        if let r = rows { ta.rows(r) }
        if let c = cols { ta.cols(c) }
        if let p = placeholder { ta.placeholder(p) }
        if disabled { ta.disabled() }
        if readonly { ta.readonly() }
        ta.addAttribute(.script("""
(function() {
  var el = document.getElementById('\(id)');
  var _lastVal = el.value;
  el.addEventListener('input', function(evt) {
    \(variable.builderId) = evt.target.value;
  });
  setInterval(function() {
    if (\(variable.builderId) !== _lastVal) {
      el.value = \(variable.builderId);
      _lastVal = \(variable.builderId);
    }
  }, 500);
})();
"""))
        return ta
    }

    /// Static <select>
    @discardableResult
    func Select(name: String? = nil,
                multiple: Bool = false,
                size: Int? = nil,
                disabled: Bool = false,
                _ content: WebComposerClosure)
    -> WebSelectElement {
        let sel = WebSelectElement()
        populateCreatedObject(sel)
        sel.elementName = "select"
        sel.class("form-select")
        if let n = name { sel.name(n) }
        if multiple { sel.multiple() }
        if let s = size { sel.size(s) }
        if disabled { sel.disabled() }
        stack.append(sel)
        content()
        stack.removeAll(where: { $0.builderId == sel.builderId })
        return sel
    }

    /// Bound <select> (single-select only)
    @discardableResult
    func Select(_ variable: WebVariableElement,
                disabled: Bool = false,
                _ content: WebComposerClosure)
    -> WebSelectElement {
        let sel = WebSelectElement()
        populateCreatedObject(sel)
        sel.elementName = "select"
        sel.class("form-select")
        let id = "select_\(sel.builderId)"
        sel.id(id)
        if let n = variable.internalName { sel.name(n) }
        if disabled { sel.disabled() }
        stack.append(sel)
        content()
        stack.removeAll(where: { $0.builderId == sel.builderId })
        let initial = variable.asString().replacingOccurrences(of: "\"", with: "\\\"")
        sel.addAttribute(.script("""
(function() {
  var el = document.getElementById('\(id)');
  var _lastVal = "\(initial)";
  el.value = _lastVal;
  el.addEventListener('change', function(evt) {
    \(variable.builderId) = evt.target.value;
  });
  setInterval(function() {
    if (\(variable.builderId) !== _lastVal) {
      el.value = \(variable.builderId);
      _lastVal = \(variable.builderId);
    }
  }, 500);
})();
"""))
        return sel
    }

    /// <option> inside select
    @discardableResult
    func Option(_ title: String,
                value: String,
                selected: Bool = false,
                disabled: Bool = false)
    -> WebOptionElement {
        guard let _ = stack.last as? WebSelectElement else {
            fatalError("Option must be inside Select { ... } block")
        }
        let opt = WebOptionElement()
        populateCreatedObject(opt)
        opt.elementName = "option"
        opt.value(value)
        if selected { opt.selected() }
        if disabled { opt.disabled() }
        opt.innerHTML(title)
        return opt
    }
}
