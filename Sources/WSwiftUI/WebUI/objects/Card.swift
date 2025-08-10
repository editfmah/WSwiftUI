//
//  Card.swift
//  SWWebAppServer
//
//  Created by Adrian on 07/07/2025.
//

import Foundation

// 1) Dedicated subclasses for Card and its sub-elements
public class WebCardElement: CoreWebContent {}
public class WebCardHeaderElement: CoreWebContent {}
public class WebCardBodyElement: CoreWebContent {}
public class WebCardFooterElement: CoreWebContent {}
public class WebCardImageElement: CoreWebContent {}

// 2) Fluent modifiers for Card container
public extension WebCardElement {
    /// Base Bootstrap card class
    @discardableResult
    func `default`() -> Self {
        addAttribute(.class("card"))
        return self
    }

    /// Adds a border to the card
    @discardableResult
    func bordered() -> Self {
        addAttribute(.class("border"))
        return self
    }

    /// Adds a shadow to the card
    @discardableResult
    func shadow() -> Self {
        addAttribute(.class("shadow"))
        return self
    }

    /// Aligns text inside the card ('start', 'center', 'end')
    @discardableResult
    func textAlign(_ alignment: String) -> Self {
        addAttribute(.class("text-\(alignment)"))
        return self
    }
}

// 3) Fluent modifiers for Card images
public extension WebCardImageElement {
    /// Makes image responsive (fluid)
    @discardableResult
    func responsive() -> Self {
        addAttribute(.class("img-fluid"))
        return self
    }

    /// Rounds image corners
    @discardableResult
    func rounded() -> Self {
        addAttribute(.class("rounded"))
        return self
    }
}

// 4) DSL factories on BaseWebEndpoint
public extension CoreWebEndpoint {
    // Internal create overload for Card
    fileprivate func createCard(_ `init`: (_ element: WebCardElement) -> Void) -> WebCardElement {
        let element = WebCardElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }

    // Internal create overload for sub-elements
    fileprivate func createCardHeader(_ `init`: (_ element: WebCardHeaderElement) -> Void) -> WebCardHeaderElement {
        let element = WebCardHeaderElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }
    fileprivate func createCardBody(_ `init`: (_ element: WebCardBodyElement) -> Void) -> WebCardBodyElement {
        let element = WebCardBodyElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }
    fileprivate func createCardFooter(_ `init`: (_ element: WebCardFooterElement) -> Void) -> WebCardFooterElement {
        let element = WebCardFooterElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }
    fileprivate func createCardImage(_ `init`: (_ element: WebCardImageElement) -> Void) -> WebCardImageElement {
        let element = WebCardImageElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }

    /// Builds a `<div class="card">…</div>` container
    @discardableResult
    func Card(_ content: WebComposerClosure) -> WebCardElement {
        let card = createCard { el in
            el.elementName = "div"
            el.class("card")
        }
        // allow additional modifiers like .bordered(), .shadow()
        card.default()
        stack.append(card)
        content()
        stack.removeAll(where: { $0.builderId == card.builderId })
        return card
    }

    /// Builds a `<div class="card-header">…</div>`; must be inside a Card
    @discardableResult
    func CardHeader(_ content: WebComposerClosure) -> WebCardHeaderElement {
        guard let _ = stack.last as? WebCardElement else {
            fatalError("CardHeader must be used inside a Card { ... } block")
        }
        let header = createCardHeader { el in
            el.elementName = "div"
            el.class("card-header")
        }
        stack.append(header)
        content()
        stack.removeAll(where: { $0.builderId == header.builderId })
        return header
    }

    /// Builds a `<div class="card-body">…</div>`; must be inside a Card
    @discardableResult
    func CardBody(_ content: WebComposerClosure) -> WebCardBodyElement {
        guard let _ = stack.last as? WebCardElement else {
            fatalError("CardBody must be used inside a Card { ... } block")
        }
        let body = createCardBody { el in
            el.elementName = "div"
            el.class("card-body")
        }
        stack.append(body)
        content()
        stack.removeAll(where: { $0.builderId == body.builderId })
        return body
    }

    /// Builds a `<div class="card-footer">…</div>`; must be inside a Card
    @discardableResult
    func CardFooter(_ content: WebComposerClosure) -> WebCardFooterElement {
        guard let _ = stack.last as? WebCardElement else {
            fatalError("CardFooter must be used inside a Card { ... } block")
        }
        let footer = createCardFooter { el in
            el.elementName = "div"
            el.class("card-footer")
        }
        stack.append(footer)
        content()
        stack.removeAll(where: { $0.builderId == footer.builderId })
        return footer
    }

    /// Builds an image with class="card-img-top"; can be chained with .responsive(), .rounded()
    @discardableResult
    func CardImageTop(src: String, alt: String = "") -> WebCardImageElement {
        let img = createCardImage { el in
            el.elementName = "img"
            el.class("card-img-top")
            el.src(src)
            if !alt.isEmpty { el.alt(alt) }
        }
        return img
    }

    /// Builds an image with class="card-img-bottom"; can be chained with .responsive(), .rounded()
    @discardableResult
    func CardImageBottom(src: String, alt: String = "") -> WebCardImageElement {
        let img = createCardImage { el in
            el.elementName = "img"
            el.class("card-img-bottom")
            el.src(src)
            if !alt.isEmpty { el.alt(alt) }
        }
        return img
    }
}
