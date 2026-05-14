import Foundation
import WSwiftUI

class LayoutControlsPage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Controls"

    var menuSecondary: String? = "Layout & Stacks"

    override func content() -> Any? {
        return DemoPage(
            title: "Layout Controls",
            subtitle: "Demonstrations for VStack, HStack, Flex, Spacer, and layout modifiers."
        ) {
            DemoSection(
                "VStack + HStack",
                description: "Compose rows and columns with nested stacks.",
                code: """
HStack {
    VStack {
        Text("Left column")
    }
    VStack {
        Text("Right column")
    }
}
"""
            ) {
                HStack {
                    VStack {
                        Badge("Column A", variant: .primary, pill: true)
                        Text("VStack content")
                    }
                    VStack {
                        Badge("Column B", variant: .success, pill: true)
                        Text("More VStack content")
                    }
                }.padding(16).background(.custom("rgba(245,248,255,1)"))
            }

            DemoSection(
                "Flex + Spacer",
                description: "Use Flex for bootstrap-style flex layout and Spacer for flexible gaps.",
                code: """
Flex {
    Badge("Start", variant: .secondary)
    Spacer()
    Badge("Middle", variant: .info)
    Spacer()
    Badge("End", variant: .dark)
}
.alignItems(.center)
"""
            ) {
                Flex {
                    Badge("Start", variant: .secondary)
                    Spacer()
                    Badge("Middle", variant: .info)
                    Spacer()
                    Badge("End", variant: .dark)
                }
                .alignItems(.center)
                .direction(.row)
                .padding(12)
                .background(.custom("rgba(245,248,255,1)"))
            }

            DemoSection(
                "Layout modifiers",
                description: "The fluent API supports frame sizing, edge padding/margins, and grouped edges.",
                code: """
Text("Framed element")
    .padding()
    .frame(width: 320, height: 80, alignment: .center)
    .margin(.bottom, 12)
"""
            ) {
                Text("Framed element")
                    .padding()
                    .frame(width: 320, height: 80, alignment: .center)
                    .background(.custom("rgba(227, 243, 255, 1)"))
                    .margin(.bottom, 12)

                Text("Horizontal + vertical edge modifiers")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(.lightgrey)
            }
            
            InteractiveBindingActionsSection(pageKey: "layout")
        }
    }

    var controller: String? = "controls"

    var method: String? = "layout"

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
