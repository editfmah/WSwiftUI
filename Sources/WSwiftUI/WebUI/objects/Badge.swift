//
//  Badge.swift
//  SWWebAppServer
//
//  Created by Adrian on 07/07/2025.
//

import Foundation

// 1) Dedicated subclass for Badge
public class WebBadgeElement: WebCoreElement {}

// 2) Variant enum matching Bootstrap badge contextual colors
public enum BootstrapVariant: String {
    case primary, secondary, success, danger, warning, info, light, dark
}

// 3) Fluent modifiers for Badge
public extension WebBadgeElement {
    /// Sets the badge color variant (`bg-<variant>`)
    @discardableResult
    func variant(_ variant: BootstrapVariant) -> Self {
        addAttribute(.variant(variant))
        addAttribute(.class("bg-\(variant.rawValue)"))
        return self
    }

    /// Makes the badge a pill (`rounded-pill`)
    @discardableResult
    func pill(_ isPill: Bool = true) -> Self {
        if isPill {
            addAttribute(.class("rounded-pill"))
        }
        return self
    }

    /// Adds an optional link style (`text-decoration-none`)
    @discardableResult
    func linkStyle(_ enable: Bool = true) -> Self {
        if enable {
            addAttribute(.class("text-decoration-none"))
        }
        return self
    }
}

// 4) DSL factory on BaseWebEndpoint
public extension CoreWebEndpoint {
    /// Renders a `<span class="badge bg-<variant> [rounded-pill]">` with provided text
    @discardableResult
    func Badge(_ title: String,
               variant: BootstrapVariant = .primary,
               pill: Bool = false,
               linkStyle: Bool = false) -> WebBadgeElement {
        let badge = WebBadgeElement()
        populateCreatedObject(badge)
        badge.elementName = "span"
        badge.addAttribute(.class("badge"))
        badge.addAttribute(.class("bg-\(variant.rawValue)"))
        if pill {
            badge.addAttribute(.class("rounded-pill"))
        }
        if linkStyle {
            badge.addAttribute(.class("text-decoration-none"))
        }
        badge.innerHTML(title)
        return badge
    }
}
