//
//  Spacer.swift
//  SWWebAppServer
//
//  Created by Adrian on 08/07/2025.
//

import Foundation

// 1) Dedicated subclass for Spacer element
public class WebSpacerElement: WebCoreElement {}

// 2) Fluent modifiers for Spacer
public extension WebSpacerElement {
    /// Enable flex-grow
    @discardableResult
    func grow(_ enabled: Bool = true) -> Self {
        if enabled {
            addAttribute(.class("flex-grow-1"))
        } else {
            addAttribute(.class("flex-grow-0"))
        }
        return self
    }

    /// Enable flex-shrink
    @discardableResult
    func shrink(_ enabled: Bool = true) -> Self {
        if enabled {
            addAttribute(.class("flex-shrink-1"))
        } else {
            addAttribute(.class("flex-shrink-0"))
        }
        return self
    }

    /// Optionally set alignment for self (overrides container align-items)
    @discardableResult
    func alignSelf(_ align: String) -> Self {
        addAttribute(.class("align-self-\(align)"))
        return self
    }
}

// 3) DSL factory on BaseWebEndpoint
public extension BaseWebEndpoint {
    /// Inserts a Spacer (<div class="flex-grow-1">) in a flex container
    @discardableResult
    func Spacer() -> WebSpacerElement {
        let spacer = WebSpacerElement()
        populateCreatedObject(spacer)
        spacer.elementName = "div"
        spacer.grow()
        return spacer
    }
}
