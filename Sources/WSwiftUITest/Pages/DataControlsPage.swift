import Foundation
import WSwiftUI

class DataControlsPage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Controls"

    var menuSecondary: String? = "Data Display"

    override func content() -> Any? {
        return DemoPage(
            title: "Data Display Controls",
            subtitle: "Tables, lists, navigation aids, and grouped data components."
        ) {
            DemoSection(
                "Table",
                description: "Compose table structures with TableHeader, TableBody, Row, and Cell.",
                code: """
Table {
    TableHeader { ... }
    TableBody { ... }
}.striped().bordered().hover()
"""
            ) {
                Table {
                    TableHeader {
                        Row {
                            Cell { Text("Name").bold() }
                            Cell { Text("Role").bold() }
                            Cell { Text("Status").bold() }
                        }
                    }
                    TableBody {
                        Row {
                            Cell { Text("Alex") }
                            Cell { Text("Admin") }
                            Cell { Badge("Active", variant: .success, pill: true) }
                        }
                        Row {
                            Cell { Text("Sam") }
                            Cell { Text("Editor") }
                            Cell { Badge("Pending", variant: .warning, pill: true) }
                        }
                    }
                }
                .striped()
                .bordered()
                .hover()
            }

            DemoSection(
                "ListGroup",
                description: "Create contextual list rows with optional active/disabled states.",
                code: """
ListGroup {
    ListGroupItem("Dashboard", variant: .primary)
    ListGroupItem("Reports", active: true)
    ListGroupItem("Archive", disabled: true)
}
"""
            ) {
                ListGroup {
                    ListGroupItem("Dashboard", variant: .primary)
                    ListGroupItem("Reports", active: true)
                    ListGroupItem("Archive", disabled: true)
                }
            }

            DemoSection(
                "Breadcrumb + Pagination",
                description: "Use Breadcrumb for location context and Pagination for page navigation.",
                code: """
Breadcrumb {
    BreadcrumbItem(title: "Home", url: "/")
    BreadcrumbItem(title: "Controls", url: "/controls")
    BreadcrumbItem(title: "Data", url: "/controls/data", active: true)
}

Pagination(alignment: .center) {
    PaginationItem(page: 1, href: "/controls/layout")
    PaginationItem(page: 2, href: "/controls/content")
    PaginationItem(page: 3, href: "/controls/data", active: true)
}
"""
            ) {
                Breadcrumb {
                    BreadcrumbItem(title: "Home", url: "/")
                    BreadcrumbItem(title: "Controls", url: "/controls")
                    BreadcrumbItem(title: "Data", url: "/controls/data", active: true)
                }

                Pagination(alignment: .center) {
                    PaginationItem(page: 1, href: "/controls/layout")
                    PaginationItem(page: 2, href: "/controls/content")
                    PaginationItem(page: 3, href: "/controls/data", active: true)
                    PaginationItem(page: 4, href: "/controls/forms")
                }.margin(.top, 8)
            }

            DemoSection(
                "Accordion",
                description: "Accordion sections are useful for FAQs and progressively-disclosed content.",
                code: """
Accordion {
    AccordionItem(title: "Question one") { Text("Answer") }
    AccordionItem(title: "Question two") { Text("Answer") }
}.expandFirst(true)
"""
            ) {
                Accordion {
                    AccordionItem(title: "What is WSwiftUI?") {
                        Text("A Swift DSL for server-rendered web UIs with client-side interactivity.")
                    }
                    AccordionItem(title: "Can I keep using Bootstrap classes?") {
                        Text("Yes. Controls are Bootstrap-friendly and fluent modifiers can add custom classes/styles.")
                    }
                }.expandFirst(true)
            }

            DemoSection(
                "Carousel",
                description: "Carousel composes indicators, slides, and prev/next controls.",
                code: """
Carousel(id: "demoCarousel", interval: 2500, fade: true) {
    CarouselIndicators(id: "demoCarousel", count: 3)
    CarouselInner {
        CarouselItem(active: true) { ... }
        CarouselItem { ... }
        CarouselItem { ... }
    }
    CarouselControlPrev(id: "demoCarousel")
    CarouselControlNext(id: "demoCarousel")
}
"""
            ) {
                Carousel(id: "demoCarousel", interval: 2500, fade: true) {
                    CarouselIndicators(id: "demoCarousel", count: 3, activeIndex: 0)
                    CarouselInner {
                        CarouselItem(active: true) {
                            Image("https://picsum.photos/seed/carousel-1/900/260", alt: "Slide 1").responsive()
                        }
                        CarouselItem {
                            Image("https://picsum.photos/seed/carousel-2/900/260", alt: "Slide 2").responsive()
                        }
                        CarouselItem {
                            Image("https://picsum.photos/seed/carousel-3/900/260", alt: "Slide 3").responsive()
                        }
                    }
                    CarouselControlPrev(id: "demoCarousel")
                    CarouselControlNext(id: "demoCarousel")
                }
            }

            DemoSection(
                "Chart",
                description: "Chart imports Chart.js automatically on use and renders using typed ChartData/ChartDataSet models.",
                code: """
let salesSplit = ChartDataSet(label: "Sales split", values: [4, 3, 2, 1])
    .background([.blue, .green, .orange, .purple])
    .border(.white)
    .borderWidth(2)

Chart(
    type: .doughnut,
    data: ChartData(
        labels: ["Enterprise", "Pro", "Starter", "Trials"],
        dataSets: [salesSplit]
    ),
    options: ChartOptions(maintainAspectRatio: true, title: "Sales split by plan")
)
"""
            ) {
                let salesSplit = ChartDataSet(label: "Sales split", values: [4, 3, 2, 1])
                    .background([.blue, .green, .orange, .purple])
                    .border(.white)
                    .borderWidth(2)

                Chart(
                    type: .doughnut,
                    data: ChartData(
                        labels: ["Enterprise", "Pro", "Starter", "Trials"],
                        dataSets: [salesSplit]
                    ),
                    options: ChartOptions(maintainAspectRatio: true, title: "Sales split by plan")
                )
            }
            
            InteractiveBindingActionsSection(pageKey: "data")
        }
    }

    var controller: String? = "controls"

    var method: String? = "data"

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
