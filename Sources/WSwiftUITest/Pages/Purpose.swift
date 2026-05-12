import Foundation
import WSwiftUI

class ControlsOverviewPage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Controls"

    var menuSecondary: String? = "Overview"

    override func content() -> Any? {
        return DemoPage(
            title: "Controls Overview",
            subtitle: "Browse all control demonstration pages in WSwiftUITest."
        ) {
            DemoSection(
                "Control categories",
                description: "Each page includes live examples and code snippets showing how to use the controls."
            ) {
                Table {
                    TableHeader {
                        Row {
                            Cell { Text("Page").bold() }
                            Cell { Text("Demonstrates").bold() }
                        }
                    }
                    TableBody {
                        Row {
                            Cell { Link("/controls/layout", title: "/controls/layout") }
                            Cell { Text("VStack, HStack, Flex, Spacer, frame/padding/margin") }
                        }
                        Row {
                            Cell { Link("/controls/content", title: "/controls/content") }
                            Cell { Text("Text, Link, Image, Audio, Badge, Callout, Jumbotron, Card, Code") }
                        }
                        Row {
                            Cell { Link("/controls/data", title: "/controls/data") }
                            Cell { Text("Table, ListGroup, Breadcrumb, Pagination, Accordion, Carousel") }
                        }
                        Row {
                            Cell { Link("/controls/forms", title: "/controls/forms") }
                            Cell { Text("Form, TextField, SecureField, TextArea, Toggle, Picker, FileUploader") }
                        }
                        Row {
                            Cell { Link("/controls/feedback", title: "/controls/feedback") }
                            Cell { Text("Alert, Modal, Sheet, OffCanvas, Progress, Spinner") }
                        }
                        Row {
                            Cell { Link("/controls/navigation", title: "/controls/navigation") }
                            Cell { Text("NavBar, NavBarItem, NavDropdown, NavDropdownItem, NavDropdownHeader, Footer") }
                        }
                        Row {
                            Cell { Link("/controls/realtime", title: "/controls/realtime") }
                            Cell { Text("WebSocket, Text(format:bindings), actions/events integration") }
                        }
                    }
                }
                .striped()
                .bordered()
                .hover()
            }

            DemoSection(
                "Template-level controls",
                description: "Each page in this demo also uses webpage/head/nav/footer controls through the shared Template helper.",
                code: """
Template {
    head(.styleLink(href: "https://cdn.jsdelivr.net/.../bootstrap.min.css"))
    NavBar(brand: "WSwiftUI") { ... }
    content()
    Footer { ... }.sticky()
}
"""
            ) {
                Text("Template controls are active across all pages in this demo app.")
            }
        }
    }

    var controller: String? = "controls"

    var method: String? = nil

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
