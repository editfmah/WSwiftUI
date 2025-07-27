//
//  Picker.swift
//  SWWebAppServer
//
//  Created by Adrian on 07/07/2025.
//

import Foundation

// 1) Dedicated subclasses for Picker (dropdown) and its parts
public class WebPickerElement: WebCoreElement {}
public class WebPickerToggleElement: WebCoreElement {}
public class WebPickerMenuElement: WebCoreElement {}
public class WebPickerItemElement: WebCoreElement {}

// 2) Option enums for Picker
public enum PickerVariant: String {
    case primary, secondary, success, danger, warning, info, light, dark, link
}

public enum PickerSize: String {
    case small = "btn-sm"
    case large = "btn-lg"
}

public enum PickerDirection: String {
    case down    = ""
    case up      = "dropup"
    case end     = "dropend"
    case start   = "dropstart"
}

public enum PickerAlignment: String {
    case start = ""
    case end   = "dropdown-menu-end"
}

// 3) Fluent modifiers on Picker container
public extension WebPickerElement {
    /// Set drop direction (`dropup`, `dropend`, `dropstart`)
    @discardableResult
    func direction(_ dir: PickerDirection) -> Self {
        if !dir.rawValue.isEmpty {
            addAttribute(.class(dir.rawValue))
        }
        return self
    }
}

// 4) Fluent modifiers on toggle button
public extension WebPickerToggleElement {
    /// Base btn
    @discardableResult
    func `default`() -> Self {
        addAttribute(.class("btn"))
        return self
    }
    /// Variant (`btn-<variant>`)
    @discardableResult
    func variant(_ v: PickerVariant) -> Self {
        addAttribute(.class("btn-\(v.rawValue)"))
        return self
    }
    /// Size (`btn-sm` / `btn-lg`)
    @discardableResult
    func size(_ s: PickerSize) -> Self {
        addAttribute(.class(s.rawValue))
        return self
    }
    /// Split toggle button
    @discardableResult
    func split(_ isSplit: Bool = true) -> Self {
        addAttribute(.class(isSplit ? "dropdown-toggle-split" : "dropdown-toggle"))
        return self
    }
}

// 5) Fluent modifiers on menu
public extension WebPickerMenuElement {
    /// Alignment end
    @discardableResult
    func align(_ align: PickerAlignment) -> Self {
        if !align.rawValue.isEmpty {
            addAttribute(.class(align.rawValue))
        }
        return self
    }
}

// 6) Fluent modifiers on items
public extension WebPickerItemElement {
    /// Disable item
    @discardableResult
    func disabled(_ isDisabled: Bool = true) -> Self {
        if isDisabled {
            addAttribute(.class("disabled"))
            addAttribute(.custom("aria-disabled=\"true\""))
        }
        return self
    }
    /// Mark active
    @discardableResult
    func active(_ isActive: Bool = true) -> Self {
        if isActive {
            addAttribute(.class("active"))
        }
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
    fileprivate func createPickerToggle(_ init: (WebPickerToggleElement) -> Void) -> WebPickerToggleElement {
        let el = WebPickerToggleElement()
        populateCreatedObject(el)
        `init`(el)
        return el
    }
    fileprivate func createPickerMenu(_ init: (WebPickerMenuElement) -> Void) -> WebPickerMenuElement {
        let el = WebPickerMenuElement()
        populateCreatedObject(el)
        `init`(el)
        return el
    }
    fileprivate func createPickerItem(_ init: (WebPickerItemElement) -> Void) -> WebPickerItemElement {
        let el = WebPickerItemElement()
        populateCreatedObject(el)
        `init`(el)
        return el
    }

    /// Main Picker container (dropdown)
    @discardableResult
    func Picker(_ title: String,
                variant: PickerVariant = .secondary,
                size: PickerSize? = nil,
                split: Bool = false,
                direction: PickerDirection = .down,
                alignment: PickerAlignment = .start,
                _ content: WebComposerClosure)
    -> WebPickerElement {
        let picker = createPicker { el in
            el.elementName = "div"
            el.class("dropdown")
            el.direction(direction)
        }
        stack.append(picker)

        // Toggle
        _ = createPickerToggle { btn in
            btn.elementName = "button"
            btn.type("button")
            btn.default()
            btn.variant(variant)
            if let s = size { btn.size(s) }
            btn.split(split)
            btn.addAttribute(.custom("data-bs-toggle=\"dropdown\""))
            btn.addAttribute(.custom("aria-expanded=\"false\""))
            btn.innerHTML(title)
        }

        // Menu
        let menu = createPickerMenu { m in
            m.elementName = "ul"
            m.class("dropdown-menu")
            m.align(alignment)
        }
        stack.append(menu)
        // items go here
        content()
        // pop menu and picker
        stack.removeAll(where: { $0.builderId == menu.builderId })
        stack.removeAll(where: { $0.builderId == picker.builderId })

        return picker
    }

    /// Picker item (<li><a class="dropdown-item" href=...>)
    @discardableResult
    func PickerItem(title: String,
                    href: String? = nil,
                    disabled: Bool = false) -> WebPickerItemElement {
        guard stack.last is WebPickerMenuElement else {
            fatalError("PickerItem must be used inside Picker { ... } block")
        }
        let item = createPickerItem { el in
            el.elementName = "li"
        }
        stack.append(item)
        // link
        _ = createPickerItem { link in
            link.elementName = "a"
            link.class("dropdown-item")
            if let u = href { link.href(u) }
            link.innerHTML(title)
            if disabled { link.disabled(true) }
        }
        stack.removeAll(where: { $0.builderId == item.builderId })
        return item
    }
}
