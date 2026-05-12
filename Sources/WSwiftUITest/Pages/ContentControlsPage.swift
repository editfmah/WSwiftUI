import Foundation
import WSwiftUI

class ContentControlsPage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Controls"

    var menuSecondary: String? = "Content & Media"

    override func content() -> Any? {
        return DemoPage(
            title: "Content & Media Controls",
            subtitle: "Text, links, media, highlights, and compositional content controls."
        ) {
            DemoSection(
                "Text + Link",
                description: "Use Text for static, bound, and formatted output; Link creates anchored navigation.",
                code: """
Text("Welcome to WSwiftUI").font(.title).bold()
Link("/controls/forms", title: "Go to forms demo")
"""
            ) {
                Text("Welcome to WSwiftUI").font(.title).bold()
                Text("Fluent modifiers let you style text quickly.")
                Link("/controls/forms", title: "Go to forms demo")
            }

            DemoSection(
                "Badge + Callout",
                description: "Badge provides compact status markers and Callout highlights key information.",
                code: """
Badge("Beta", variant: .warning, pill: true)
Callout(.info) {
    Text("Important guidance here.")
}
"""
            ) {
                HStack {
                    Badge("Beta", variant: .warning, pill: true)
                    Badge("Stable", variant: .success, pill: true)
                    Badge("Deprecated", variant: .danger, pill: true)
                }.padding(.bottom, 12)

                Callout(.info) {
                    Text("Callout blocks are useful for notes, warnings, and contextual guidance.")
                }
            }

            DemoSection(
                "Image + Audio",
                description: "Image supports responsive helpers and Audio exposes common playback attributes.",
                code: """
Image("https://picsum.photos/seed/wsui/640/220", alt: "Demo")
    .responsive()
    .rounded()

Audio("https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")
    .preload("metadata")
"""
            ) {
                Image("https://picsum.photos/seed/wsui/640/220", alt: "Demo image")
                    .responsive()
                    .rounded()
                    .margin(.bottom, 12)

                Audio("https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")
                    .preload("metadata")
            }

            DemoSection(
                "Jumbotron",
                description: "Jumbotron creates a full-width hero block for top-level page messaging.",
                code: """
Jumbotron(fluid: true) {
    JumbotronTitle("Launch faster")
    JumbotronSubtitle("Compose HTML in Swift with fluent APIs.")
}
"""
            ) {
                Jumbotron(fluid: true) {
                    JumbotronTitle("Launch faster")
                    JumbotronSubtitle("Compose HTML in Swift with fluent APIs.")
                }
            }

            DemoSection(
                "Card composition",
                description: "Cards support headers, body, footers, and top/bottom media.",
                code: """
Card {
    CardHeader { Text("Card Header") }
    CardImageTop(src: "https://picsum.photos/seed/card/640/200")
    CardBody { Text("Card body content") }
    CardImageBottom(src: "https://picsum.photos/seed/card-bottom/640/120")
    CardFooter { Text("Footer metadata") }
}.shadow()
"""
            ) {
                Card {
                    CardHeader {
                        Text("Card Header").bold()
                    }
                    CardImageTop(src: "https://picsum.photos/seed/card/640/200", alt: "Card image")
                    CardBody {
                        Text("Cards are great for grouping related content and actions.")
                    }
                    CardImageBottom(src: "https://picsum.photos/seed/card-bottom/640/120", alt: "Card bottom image")
                    CardFooter {
                        Text("Footer metadata")
                    }
                }.shadow().bordered()
            }

            DemoSection(
                "Code",
                description: "Code renders syntax-highlight-friendly code blocks.",
                code: """
Code(language: .swift, "let server = WSwiftServer(port: 4242)")
"""
            ) {
                Code(language: .swift, """
let server = WSwiftServer(port: 4242)
server.register(HomePage())
""")
            }
        }
    }

    var controller: String? = "controls"

    var method: String? = "content"

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
