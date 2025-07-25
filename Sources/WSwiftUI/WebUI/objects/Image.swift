//
//  Image.swift
//  SWWebAppServer
//
//  Created by Adrian on 05/07/2025.
//
import Foundation

public class WebImageElement: WebCoreElement {}

public extension WebImageElement {


    /// Adds Bootstrap’s `.img-fluid` class
    @discardableResult
    func responsive() -> Self {
        addAttribute(.class("img-fluid"))
        return self
    }

    /// Adds Bootstrap’s `.img-thumbnail` class
    @discardableResult
    func thumbnail() -> Self {
        addAttribute(.class("img-thumbnail"))
        return self
    }

    /// Adds a `rounded` class
    @discardableResult
    func rounded() -> Self {
        addAttribute(.class("rounded"))
        return self
    }
    
    /// Enables native lazy-loading (`loading="lazy"`)
    @discardableResult
    func lazyLoad() -> Self {
        addAttribute(.custom("loading=\"lazy\""))
        return self
    }

    /// Sets object-fit via inline style
    @discardableResult
    func objectFit(_ fit: String) -> Self {
        // e.g. "cover", "contain", etc.
        addAttribute(.style("object-fit: \(fit);"))
        return self
    }
}


public extension BaseWebEndpoint {
    
    fileprivate func create(_ init: (_ element: WebImageElement) -> Void) -> WebImageElement {
        
        let element = WebImageElement()
        populateCreatedObject(element)
        `init`(element)
        return element
        
    }
    
    @discardableResult
    func Image(_ src: String, alt: String = "") -> WebImageElement {
        let img: WebImageElement = create { el in
            el.elementName = "img"
            el.class(el.builderId)       // so we can target it via JS/CSS if needed
            el.src(src)
            if !alt.isEmpty { el.alt(alt) }
        }
        return img
    }
}

