//
//  JumboTron.swift
//  SWWebAppServer
//
//  Created by Adrian on 11/07/2025.
//

import Foundation

/// The “hero” banner at the top of a page
public class WebJumbotronElement: WebCoreElement {}
public class WebJumbotronImageElement: WebCoreElement {}
public class WebJumbotronTitleElement: WebCoreElement {}
public class WebJumbotronSubtitleElement: WebCoreElement {}

public extension BaseWebEndpoint {
  /// Creates a full-width jumbotron banner.
  ///
  /// - Parameters:
  ///   - fluid: if true, uses `.container-fluid` inside; otherwise `.container`
  ///   - bgImageURL: optional URL for a background image
  ///   - content: closure in which to call `JumbotronTitle`, `JumbotronSubtitle`, or any other elements
  @discardableResult
  func Jumbotron(
    fluid: Bool = false,
    bgImageURL: String? = nil,
    _ content: WebComposerClosure
  ) -> WebJumbotronElement {
    // 1) root <div class="jumbotron p-5 mb-4 bg-light rounded-3">
    let jumbo = WebJumbotronElement()
    populateCreatedObject(jumbo)
    jumbo.elementName = "div"
    jumbo.addAttribute(.class("jumbotron p-5 mb-4 bg-light rounded-3"))
    if let url = bgImageURL {
      jumbo.addAttribute(.style("background-image: url('\(url)'); background-size: cover;"))
    }

    // push the jumbotron
    stack.append(jumbo)

    // 2) inner container
    let container = WebCoreElement()
    populateCreatedObject(container)
    container.elementName = "div"
    container.addAttribute(.class(fluid ? "container-fluid" : "container"))
    stack.append(container)

    // 3) user content (titles, buttons, etc.)
    content()

    // 4) pop container + jumbo
    stack.removeLast()
    stack.removeLast()

    return jumbo
  }

  /// A large heading inside a Jumbotron
  @discardableResult
  func JumbotronTitle(_ text: String) -> WebJumbotronTitleElement {
    let h1 = WebJumbotronTitleElement()
    populateCreatedObject(h1)
    h1.elementName = "h1"
    h1.addAttribute(.class("display-4"))
    h1.innerHTML(text)
    return h1
  }

  /// A subtitle / lead text inside a Jumbotron
  @discardableResult
  func JumbotronSubtitle(_ text: String) -> WebJumbotronSubtitleElement {
    let p = WebJumbotronSubtitleElement()
    populateCreatedObject(p)
    p.elementName = "p"
    p.addAttribute(.class("lead"))
    p.innerHTML(text)
    return p
  }
}
