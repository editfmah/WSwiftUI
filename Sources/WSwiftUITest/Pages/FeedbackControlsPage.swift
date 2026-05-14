import Foundation
import WSwiftUI

class FeedbackControlsPage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Controls"

    var menuSecondary: String? = "Feedback & Overlays"

    override func content() -> Any? {
        let showStateAlert = WBool(false)
        let showModal = WBool(false)
        let showSheet = WBool(false)
        let showOffCanvas = WBool(false)
        let progressValue = WInt(40)

        return DemoPage(
            title: "Feedback & Overlay Controls",
            subtitle: "Alerts, modals, off-canvas panels, progress bars, and spinners."
        ) {
            DemoSection(
                "Alert",
                description: "Use static alerts or state-driven variants with bound visibility.",
                code: """
let showAlert = WBool(false)
Button("Toggle alert").onClick(.toggle(showAlert))
Alert("Saved", isPresented: showAlert, variant: .success, message: "Changes were stored.")
"""
            ) {
                Button("Toggle state-driven alert")
                    .variant(.primary)
                    .onClick(.toggle(showStateAlert))
                    .margin(.bottom, 12)

                Alert(.info, dismissible: true) {
                    Text("This is a static dismissible alert.")
                }.margin(.bottom, 12)

                Alert(
                    "State-driven alert",
                    isPresented: showStateAlert,
                    variant: .warning,
                    message: "Visibility is controlled by a bound WBool.",
                    dismissible: true
                )
            }

            DemoSection(
                "Modal + Sheet",
                description: "Both controls are state-driven and synchronize show/hide with bound variables.",
                code: """
let showModal = WBool(false)
Button("Open modal").onClick(.setVariable(showModal, to: true))
Modal(id: "demoModal", isPresented: showModal) { ... }

let showSheet = WBool(false)
Sheet(isPresented: showSheet) { ... }
"""
            ) {
                HStack {
                    Button("Open modal")
                        .variant(.primary)
                        .onClick(.setVariable(showModal, to: true))

                    Button("Open sheet")
                        .variant(.secondary)
                        .onClick(.setVariable(showSheet, to: true))
                }.padding(.bottom, 12)

                Modal(id: "demoModal", isPresented: showModal) {
                    ModalDialog {
                        ModalContent {
                            ModalHeader {
                                ModalTitle {
                                    Text("Modal Title")
                                }
                            }
                            ModalBody {
                                Text("This modal is controlled by showModal.")
                            }
                            ModalFooter {
                                Button("Close")
                                    .variant(.secondary)
                                    .onClick(.setVariable(showModal, to: false))
                            }
                        }
                    }
                }

                Sheet(isPresented: showSheet, id: "demoSheet") {
                    ModalDialog {
                        ModalContent {
                            ModalHeader {
                                ModalTitle {
                                    Text("Sheet-style modal")
                                }
                            }
                            ModalBody {
                                Text("Sheet is an alias around Modal(isPresented:).")
                            }
                            ModalFooter {
                                Button("Done")
                                    .variant(.primary)
                                    .onClick(.setVariable(showSheet, to: false))
                            }
                        }
                    }
                }
            }

            DemoSection(
                "OffCanvas",
                description: "Off-canvas panels are useful for secondary workflows and filters.",
                code: """
let showPanel = WBool(false)
Button("Open panel").onClick(.setVariable(showPanel, to: true))
OffCanvas(id: "demoPanel", isPresented: showPanel, placement: .end) { ... }
"""
            ) {
                Button("Open off-canvas")
                    .variant(.dark)
                    .onClick(.setVariable(showOffCanvas, to: true))
                    .margin(.bottom, 12)

                OffCanvas(id: "demoPanel", isPresented: showOffCanvas, placement: .end) {
                    OffCanvasHeader {
                        OffCanvasTitle {
                            Text("Filters")
                        }
                    }
                    OffCanvasBody {
                        Text("Put additional controls here without leaving the page.")
                    }
                    OffCanvasFooter {
                        Button("Close panel")
                            .variant(.secondary)
                            .onClick(.setVariable(showOffCanvas, to: false))
                    }
                }
            }

            DemoSection(
                "Progress + Spinner",
                description: "Progress bars can be static or variable-driven, and spinners support type/size modifiers.",
                code: """
let progress = WInt(40)
Progress {
    ProgressBar(progress, max: 100, variant: .success, striped: true, animated: true)
}
Spinner("Loading").type(.grow).size(.small)
"""
            ) {
                HStack {
                    Button("25%").variant(.secondary).onClick(.setVariable(progressValue, to: 25))
                    Button("60%").variant(.secondary).onClick(.setVariable(progressValue, to: 60))
                    Button("90%").variant(.secondary).onClick(.setVariable(progressValue, to: 90))
                }.padding(.bottom, 12)

                Progress {
                    ProgressBar(progressValue, max: 100, variant: .success, striped: true, animated: true)
                }

                Progress {
                    ProgressBar(value: 60, variant: .info)
                }.height("8px").margin(.top, 10)

                HStack {
                    Spinner("Loading...")
                    Spinner("Working...")
                        .type(.grow)
                        .size(.small)
                        .foreground(.blue)
                }.padding(.top, 12)
            }
            
            InteractiveBindingActionsSection(pageKey: "feedback")
        }
    }

    var controller: String? = "controls"

    var method: String? = "feedback"

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
