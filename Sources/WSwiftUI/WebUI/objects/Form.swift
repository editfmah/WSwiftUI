//
//  Form.swift
//  SWWebAppServer
//
//  Created by Adrian on 08/07/2025.
//

import Foundation

// 1) Dedicated subclass for the <form> element
public class WebFormElement: WebCoreElement {}

// 2) Enums for method and encoding types
public enum FormMethod: String {
    case get = "get"
    case post = "post"
}

public enum FormEncType: String {
    case urlEncoded    = "application/x-www-form-urlencoded"
    case multipart      = "multipart/form-data"
    case plainText      = "text/plain"
}

// 3) Fluent modifiers for form attributes
public extension WebFormElement {
    /// Sets the form action URL
    @discardableResult
    func action(_ url: String) -> Self {
        addAttribute(.pair("action", url))
        return self
    }

    /// Sets the HTTP method (get or post)
    @discardableResult
    func method(_ method: FormMethod) -> Self {
        addAttribute(.pair("method", method.rawValue))
        return self
    }

    /// Sets the form encoding type
    @discardableResult
    func encType(_ type: FormEncType) -> Self {
        addAttribute(.pair("enctype", type.rawValue))
        return self
    }

    /// Enables or disables browser validation
    @discardableResult
    func noValidate(_ on: Bool = true) -> Self {
        if on {
            addAttribute(.custom("novalidate"))
        }
        return self
    }

    /// Sets the autocomplete attribute ("on", "off", or any valid value)
    @discardableResult
    func autoComplete(_ setting: String) -> Self {
        addAttribute(.pair("autocomplete", setting))
        return self
    }
}

// 4) DSL factory on BaseWebEndpoint
public extension CoreWebEndpoint {
    /// Creates a <form> element with optional attributes
    @discardableResult
    func Form(action: String? = nil,
              method: FormMethod = .get,
              encType: FormEncType? = nil,
              autoComplete: String? = nil,
              noValidate: Bool = false,
              _ content: WebComposerClosure) -> WebFormElement {
        let form = WebFormElement()
        populateCreatedObject(form)
        form.elementName = "form"
        form.method(method)
        if let url = action {
            form.action(url)
        }
        if let enc = encType {
            form.encType(enc)
        }
        if let auto = autoComplete {
            form.autoComplete(auto)
        }
        if noValidate {
            form.noValidate()
        }
        stack.append(form)
        content()
        stack.removeAll(where: { $0.builderId == form.builderId })
        return form
    }

    /// Convenience to add a submit button inside a form
    @discardableResult
    func SubmitButton(_ title: String = "Submit",
                       variant: ButtonStyle = .primary,
                       size: ButtonSize? = nil)
    -> WebButtonElement {
        let btn = Button(title)
        btn.type("submit")
        btn.variant(variant)
        if let s = size { btn.size(s) }
        return btn
    }
}
