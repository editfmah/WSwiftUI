//
//  template.swift
//  SWWebAppServer
//
//  Created by Adrian on 11/07/2025.
//

import Foundation
import SWWebAppServer

extension BaseWebEndpoint {
    func template(_ content: WebComposerClosure) -> WebCoreElement {
        
        webpage {
            
            head(.script(src: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"))
            head(.styleLink(href: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"))
            head(.metaViewport(content: "width=device-width, initial-scale=1"))
            
            // Dynamic navigation bar using menuEntries
            NavBar(brand: "WSwiftUI") {
                for entry in self.menuEntries {
                    if entry.children.isEmpty {
                        NavBarItem(title: entry.title,
                                   href: entry.path ?? "#",
                                   active: entry.selected)
                    } else {
                        // Dropdown for entries with children
                        let dropdownId = "navbarDropdown_\(entry.title.insertDashes())"
                        NavDropdown(title: entry.title,
                                    id: dropdownId) {
                            for child in entry.children {
                                if child.children.isEmpty {
                                    NavDropdownItem(title: child.title,
                                                    href: child.path ?? "#")
                                } else {
                                    NavDropdownHeader(child.title)
                                    for grandChild in child.children {
                                        NavDropdownItem(title: grandChild.title,
                                                        href: grandChild.path ?? "#")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            content()
            
            // Footer
            Footer() {
                VStack {
                    Text("© 2025 WSwiftUI Demo")
                        .class("text-center text-muted")
                    HStack() {
                        Link("/privacy", title: "Privacy Policy")
                        Spacer()
                        Link("/terms", title: "Terms of Service")
                    }.textalign(.center)
                    .class("mt-2")
                }
                .padding(10)
            }
            .default()
            .sticky()
            .collapseOnScroll(threshold: 100, collapsedClass: "py-1")
            
        }
    }
}
