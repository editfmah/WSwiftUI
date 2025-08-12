import Foundation

// 1) Dedicated subclass for Alert
public class WebAlertElement: WebElement {}


// 3) Fluent methods for alert behaviors
public extension WebAlertElement {
    /// Sets the alert variant (e.g. `.success`, `.danger`, etc.)
    @discardableResult
    func variant(_ variant: BootstrapVariant) -> Self {
        addAttribute(.variant(variant))
        addAttribute(.class("alert-\(variant.rawValue)"))
        return self
    }

    /// Makes the alert dismissible (`.alert-dismissible`)
    @discardableResult
    func dismissible(_ dismissible: Bool = true) -> Self {
        if dismissible {
            addAttribute(.class("alert-dismissible"))
        }
        return self
    }

    /// Applies fade transition (`.fade`)
    @discardableResult
    func fade(_ fade: Bool = true) -> Self {
        if fade {
            addAttribute(.class("fade"))
        }
        return self
    }

    /// Shows the element (`.show`)
    @discardableResult
    func show(_ show: Bool = true) -> Self {
        if show {
            addAttribute(.class("show"))
        }
        return self
    }
}

// 4) DSL on BaseWebEndpoint
public extension CoreWebEndpoint {
    /// Internal helper for creating alert elements
    fileprivate func createAlert(_ `init`: (_ element: WebAlertElement) -> Void) -> WebAlertElement {
        let element = WebAlertElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }

    /// Builds a Bootstrap alert
    @discardableResult
    func Alert(_ variant: BootstrapVariant = .primary, dismissible: Bool = false, _ content: WebComposerClosure) -> WebAlertElement {
        // Outer <div class="alert alert-<variant>" role="alert">
        let alert = createAlert { el in
            el.elementName = "div"
            el.class("alert")
            el.class("alert-\(variant.rawValue)")
            el.addAttribute(.pair("role", "alert"))
            if dismissible {
                el.class("alert-dismissible")
                el.class("fade")
                el.class("show")
            }
        }
        stack.append(alert)
        // User content goes here
        content()
        // Append close button if dismissible
        if dismissible {
            _ = createAlert { el in
                el.elementName = "button"
                el.type("button")
                el.class("btn-close")
                el.addAttribute(.custom("data-bs-dismiss=\"alert\""))
                el.addAttribute(.custom("aria-label=\"Close\""))
            }
        }
        // Pop alert from stack
        stack.removeAll(where: { $0.builderId == alert.builderId })
        return alert
    }
}
