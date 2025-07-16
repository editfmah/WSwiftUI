//
//  Link.swift
//  SWWebAppServer
//
//  Created by Adrian on 11/07/2025.
//

import Foundation

/// Represents an anchor (<a>) element within the DSL.
public class WebLinkElement: WebCoreElement {}

public extension BaseWebEndpoint {
    /// Factory to create and register a WebLinkElement with the endpoint.
    /// - Parameters:
    ///   - href: URL string for the link.
    ///   - title: Text content of the link.
    ///   - target: Optional target attribute (e.g., "_blank").
    /// - Returns: Configured WebLinkElement.
    @discardableResult
    func Link(_ href: String, title: String, target: String? = nil) -> WebCoreElement {
        let link: WebCoreElement = create { el in
            el.elementName = "a"
            el.addAttribute(.class(el.builderId))
            el.addAttribute(.href(href))
            if let t = target {
                el.addAttribute(.pair("target", t))
            }
            el.addAttribute(.innerHTML(title))
        }
        return link
    }
}
