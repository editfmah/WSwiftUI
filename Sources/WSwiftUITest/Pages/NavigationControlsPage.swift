import Foundation
import WSwiftUI

class NavigationControlsPage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Controls"

    var menuSecondary: String? = "Navigation Shell"

    override func content() -> Any? {
        return DemoPage(
            title: "Navigation & Shell Controls",
            subtitle: "Custom navbar composition and footer usage."
        ) {
            DemoSection(
                "NavBar + NavBarItem + NavDropdown",
                description: "Build custom navigation bars with links and dropdowns.",
                code: """
NavBar(brand: "Demo", color: .dark, bg: .dark) {
    NavBarItem(title: "Home", href: "/")
    NavDropdown(title: "Guides", id: "guidesMenu") {
        NavDropdownHeader("Core")
        NavDropdownItem(title: "Layout", href: "/controls/layout")
    }
}
"""
            ) {
                NavBar(brand: "Inline Demo", color: .dark, bg: .dark, useFluidContainer: true) {
                    NavBarItem(title: "Home", href: "/")
                    NavBarItem(title: "Overview", href: "/controls")
                    NavDropdown(title: "Guides", id: "guidesMenu") {
                        NavDropdownHeader("Core Controls")
                        NavDropdownItem(title: "Layout", href: "/controls/layout")
                        NavDropdownItem(title: "Forms", href: "/controls/forms")
                        NavDropdownItem(title: "Feedback", href: "/controls/feedback")
                    }
                }
            }

            DemoSection(
                "Footer",
                description: "The shared template already uses Footer on every page. You can also render standalone footers.",
                code: """
Footer {
    Text("Demo footer content")
}.default()
"""
            ) {
                Footer {
                    HStack {
                        Text("Inline footer example")
                        Spacer()
                        Link("/controls", title: "Back to controls")
                    }.padding(10)
                }
                .default()
                .background(.darkgrey)
            }
            
            InteractiveBindingActionsSection(pageKey: "navigation")
        }
    }

    var controller: String? = "controls"

    var method: String? = "navigation"

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
