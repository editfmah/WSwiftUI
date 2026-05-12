import Foundation
import WSwiftUI

class RealtimeControlsPage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Controls"

    var menuSecondary: String? = "Realtime & Actions"

    override func content() -> Any? {
        let serverTime = WString("connecting...")
        let status = WString("Idle")

        return DemoPage(
            title: "Realtime & Action Controls",
            subtitle: "WebSocket integration plus event/action composition."
        ) {
            DemoSection(
                "WebSocket + bound Text",
                description: "Incoming JSON is mapped into a reactive variable and rendered live.",
                code: """
let serverTime = WString("connecting...")
Text("Server time: $0", serverTime)
WebSocket(url: "ws://localhost:4242/ws-ping", onRecieve: [
    .extractJSONInto(key: "time", into: serverTime)
])
"""
            ) {
                Text("Server time: $0", serverTime).font(.title2)
                WebSocket(url: "ws://localhost:4242/ws-ping", onRecieve: [
                    .extractJSONInto(key: "time", into: serverTime)
                ])
            }

            DemoSection(
                "Button events + WebAction",
                description: "Actions can mutate variables and drive UI behavior without custom JS files.",
                code: """
let status = WString("Idle")
Button("Set success").onClick(.setVariable(status, to: "Saved"))
Text("Status: $0", status)
"""
            ) {
                HStack {
                    Button("Set success")
                        .variant(.success)
                        .onClick(.setVariable(status, to: "Saved"))

                    Button("Set warning")
                        .variant(.warning)
                        .onClick(.setVariable(status, to: "Needs review"))

                    Button("Reset")
                        .variant(.secondary)
                        .onClick(.setVariable(status, to: "Idle"))
                }.padding(.bottom, 12)

                Text("Status: $0", status).font(.subtitle)
            }
        }
    }

    var controller: String? = "controls"

    var method: String? = "realtime"

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
