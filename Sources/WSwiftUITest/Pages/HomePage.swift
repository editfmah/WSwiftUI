import Foundation
import WSwiftUI

class HomePage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Home"

    var menuSecondary: String?

    override func content() -> Any? {
        let currentTime = WString("connecting...")

        return DemoPage(
            title: "WSwiftUI Demo App",
            subtitle: "A complete, categorized showcase of the framework controls and fluent APIs."
        ) {
            Callout(.info) {
                Text("Use the Controls menu to browse dedicated demo pages for layout, content, data display, forms, feedback overlays, navigation, and real-time interactions.")
            }

            DemoSection(
                "Live WebSocket control demo",
                description: "This page binds a WebSocket response into a reactive variable and renders it with Text.",
                code: """
let currentTime = WString("connecting...")
Text("Server UTC time: $0", currentTime)
WebSocket(url: "ws://localhost:4242/ws-ping", onRecieve: [
    .extractJSONInto(key: "time", into: currentTime)
])
"""
            ) {
                Text("Server UTC time: $0", currentTime).font(.title2)
                WebSocket(url: "ws://localhost:4242/ws-ping", onRecieve: [
                    .extractJSONInto(key: "time", into: currentTime)
                ])
            }

            DemoSection(
                "Demo pages",
                description: "Each section focuses on a control family and includes live previews plus usage snippets."
            ) {
                ListGroup {
                    ListGroupItem("Overview", variant: .primary).onClick(.navigate("/controls"))
                    ListGroupItem("Layout & stacks", variant: .secondary).onClick(.navigate("/controls/layout"))
                    ListGroupItem("Content & media", variant: .secondary).onClick(.navigate("/controls/content"))
                    ListGroupItem("Data display", variant: .secondary).onClick(.navigate("/controls/data"))
                    ListGroupItem("Forms & inputs", variant: .secondary).onClick(.navigate("/controls/forms"))
                    ListGroupItem("Feedback & overlays", variant: .secondary).onClick(.navigate("/controls/feedback"))
                    ListGroupItem("Navigation shell", variant: .secondary).onClick(.navigate("/controls/navigation"))
                    ListGroupItem("Realtime & actions", variant: .secondary).onClick(.navigate("/controls/realtime"))
                    ListGroupItem("Actions showcase", variant: .secondary).onClick(.navigate("/controls/actions"))
                }
            }

            DemoSection(
                "Minimal endpoint pattern",
                code: """
final class ExamplePage: CoreWebEndpoint, WebEndpoint, WebContent {
    var controller: String? = "example"
    var method: String? = nil
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    override func content() -> Any? {
        Template {
            Text("Hello from WSwiftUI")
        }
    }
}
"""
            ) {
                Text("Every demo page in this app follows this pattern: endpoint + Template + fluent control composition.")
            }
            
            InteractiveBindingActionsSection(pageKey: "home")
        }
    }

    var controller: String? = nil

    var method: String? = nil

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
