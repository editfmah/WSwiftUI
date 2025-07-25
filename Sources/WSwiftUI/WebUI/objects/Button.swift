//
//  Button.swift
//  SWWebAppServer
//
//  Created by Adrian on 06/07/2025.
//

import Foundation

// 1) Dedicated subclass for Button
public class WebButtonElement: WebCoreElement {}

// 2) Button-specific enums
public enum ButtonStyle: String {
    case primary, secondary, success, danger, warning, info, light, dark, link
}

public enum ButtonSize: String {
    case small = "btn-sm"
    case large = "btn-lg"
}

// 3) Fluent methods for button behaviors
public extension WebButtonElement {
    /// Base class for all buttons (`btn`)
    @discardableResult
    func `default`() -> Self {
        addAttribute(.class("btn"))
        return self
    }

    /// Sets the button variant (e.g. `.primary`, `.secondary`, etc.)
    @discardableResult
    func variant(_ style: ButtonStyle) -> Self {
        addAttribute(.class("btn-\(style.rawValue)"))
        return self
    }

    /// Sets an outline variant (e.g. `.outline(.primary)`)
    @discardableResult
    func outline(_ style: ButtonStyle) -> Self {
        addAttribute(.class("btn-outline-\(style.rawValue)"))
        return self
    }

    /// Sets size to small or large
    @discardableResult
    func size(_ size: ButtonSize) -> Self {
        addAttribute(.class(size.rawValue))
        return self
    }

    /// Full width button (`d-block w-100`)
    @discardableResult
    func block() -> Self {
        addAttribute(.class("d-block w-100"))
        return self
    }

    /// Toggles the `active` state
    @discardableResult
    func active(_ isActive: Bool = true) -> Self {
        if isActive {
            addAttribute(.class("active"))
        }
        return self
    }

    /// Disables the button via class and attribute
    @discardableResult
    func disabled(_ isDisabled: Bool = true) -> Self {
        if isDisabled {
            addAttribute(.class("disabled"))
            self.disabled()
        }
        return self
    }
}

// 4) Factory on BaseWebEndpoint
public extension BaseWebEndpoint {
    /// Internal helper to create a button
    fileprivate func createButton(_ `init`: (_ element: WebButtonElement) -> Void) -> WebButtonElement {
        let element = WebButtonElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }

    /// Creates a `<button>` with Bootstrap classes
    @discardableResult
    func Button(_ title: String, type buttonType: String = "button") -> WebButtonElement {
        let button = createButton { el in
            el.elementName = "button"
            el.addAttribute(.type(buttonType))
            el.innerHTML(title)
        }
        // default bootstrap btn base class
        button.default()
        return button
    }
}

