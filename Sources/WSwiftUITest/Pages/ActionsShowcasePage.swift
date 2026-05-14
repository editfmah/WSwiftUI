import Foundation
import WSwiftUI

class ActionsShowcasePage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Controls"

    var menuSecondary: String? = "Actions Showcase"

    override func content() -> Any? {
        let sharedText = WString("Action-ready text").name("actions_shared_text")
        let actionStatus = WString("Idle").name("actions_status")
        let hideActionBox = WBool(false).name("actions_hide_box")
        let storageEcho = WString("Nothing loaded yet").name("actions_storage_echo")
        let progress = WInt(20).name("actions_progress")
        
        let actionBoxId = "actions_demo_box"
        let textTargetId = "actions_text_target"
        let htmlTargetId = "actions_html_target"
        
        _ = sharedText.onValueChanged([
            .setVariable(actionStatus, to: "sharedText changed")
        ])
        
        return DemoPage(
            title: "WebAction Showcase",
            subtitle: "Reference page for common actions, sequencing, and variable-driven behavior."
        ) {
            DemoSection(
                "Variable mutation + conditional actions",
                description: "Use actions to mutate bound variables, branch conditionally, and keep multiple controls synchronized.",
                code: """
Button("Set success").onClick([
    .setVariable(status, to: "Saved"),
    .setVariable(progress, to: 75)
])
Button("Check progress").onClick(
    .if(progress, .isPositive, [.setVariable(status, to: "Positive")], [.setVariable(status, to: "Zero")])
)
"""
            ) {
                TextField("Shared input A", text: sharedText, prompt: "Type here")
                TextField("Shared input B", text: sharedText, prompt: "Same variable")
                Text("Status: $0", actionStatus).font(.subtitle).padding(.top, 8)
                
                HStack(spacing: 8) {
                    Button("Set success")
                        .variant(.success)
                        .onClick([
                            .setVariable(actionStatus, to: "Saved"),
                            .setVariable(progress, to: 75)
                        ])
                    Button("Set warning")
                        .variant(.warning)
                        .onClick([
                            .setVariable(actionStatus, to: "Needs review"),
                            .setVariable(progress, to: 45)
                        ])
                    Button("Check progress")
                        .variant(.secondary)
                        .onClick(.if(progress, .isPositive, [
                            .setVariable(actionStatus, to: "Progress is positive")
                        ], [
                            .setVariable(actionStatus, to: "Progress is zero")
                        ]))
                }.margin(.top, 8)
                
                Progress {
                    ProgressBar(progress, max: 100, variant: .info, striped: true, animated: true)
                }.margin(.top, 8)
            }
            
            DemoSection(
                "Visibility, fading, class toggles, and animation",
                description: "Target elements by id and combine show/hide with fade and animation actions.",
                code: """
Button("Fade").onClick(.fadeToggle(ref: "actions_demo_box", duration: 0.25))
Button("Pulse").onClick(.addClassFor(ref: "actions_demo_box", className: "shadow-lg", durationMs: 700))
Button("Scale").onClick(.animate(ref: "actions_demo_box",
    keyframes: "[{ transform: 'scale(1)' }, { transform: 'scale(1.04)' }, { transform: 'scale(1)' }]",
    options: "{ duration: 240, easing: 'ease-in-out' }"))
"""
            ) {
                Toggle("Hide box via bound bool", isOn: hideActionBox).margin(.bottom, 8)
                
                HStack(spacing: 8) {
                    Button("Show").variant(.secondary).onClick(.show(ref: actionBoxId))
                    Button("Hide").variant(.secondary).onClick(.hide(ref: actionBoxId))
                    Button("Fade").variant(.dark).onClick(.fadeToggle(ref: actionBoxId, duration: 0.25))
                    Button("Toggle border").outline(.warning).onClick(.toggleClass(ref: actionBoxId, className: "border-warning"))
                    Button("Pulse").outline(.primary).onClick(.addClassFor(ref: actionBoxId, className: "shadow-lg", durationMs: 700))
                    Button("Scale").outline(.success).onClick(.animate(
                        ref: actionBoxId,
                        keyframes: "[{ transform: 'scale(1)' }, { transform: 'scale(1.04)' }, { transform: 'scale(1)' }]",
                        options: "{ duration: 240, easing: 'ease-in-out' }"
                    ))
                }.margin(.bottom, 10)
                
                Card {
                    CardBody {
                        Text("Action target box").bold()
                        Text("Shared text value: $0", sharedText)
                    }
                }
                .id(actionBoxId)
                .border(.all, .grey, width: 1)
                .hidden(hideActionBox)
            }
            
            DemoSection(
                "Text, HTML, attributes, and styles",
                description: "Manipulate content and attributes on specific targets without writing custom client JS.",
                code: """
Button("Set text").onClick(.text(ref: "target", "Updated text"))
Button("Set html").onClick(.html(ref: "targetHtml", "<strong>Bold</strong>"))
Button("Style").onClick(.setStyles(ref: "target", styles: ["color":"#0d6efd", "fontWeight":"700"]))
"""
            ) {
                HStack(spacing: 8) {
                    Button("Set text").variant(.secondary).onClick(.text(ref: textTargetId, "Updated via .text action"))
                    Button("Set html").variant(.secondary).onClick(.html(ref: htmlTargetId, "<strong>Bold HTML</strong> from <em>.html</em>"))
                    Button("Append").variant(.secondary).onClick(.appendHTML(ref: htmlTargetId, " <span class='badge bg-info'>+badge</span>"))
                    Button("Prepend").variant(.secondary).onClick(.prependHTML(ref: htmlTargetId, "<span class='text-muted me-2'>[prefix]</span>"))
                }.margin(.bottom, 8)
                
                HStack(spacing: 8) {
                    Button("Set attr").outline(.primary).onClick(.setAttribute(ref: textTargetId, name: "data-action-demo", value: "true"))
                    Button("Remove attr").outline(.primary).onClick(.removeAttribute(ref: textTargetId, name: "data-action-demo"))
                    Button("Style").outline(.success).onClick(.setStyles(ref: textTargetId, styles: [
                        "color": "#0d6efd",
                        "fontWeight": "700",
                        "letterSpacing": "0.02em"
                    ]))
                }.margin(.bottom, 8)
                
                Text("Target text content").id(textTargetId)
                Text("Target HTML content").id(htmlTargetId).margin(.top, 6)
            }
            
            DemoSection(
                "Storage and clipboard actions",
                description: "Persist values to local/session storage and pull them back into bound variables.",
                code: """
Button("Save local").onClick(.localStorageSet(key: "demo", value: sharedText))
Button("Load local").onClick(.localStorageGet(key: "demo", into: storageEcho))
Button("Copy").onClick(.clipboardCopy(sharedText))
"""
            ) {
                TextArea("Storage source text", text: sharedText).rows(3)
                
                HStack(spacing: 8) {
                    Button("Save local").variant(.secondary).onClick([
                        .localStorageSet(key: "wsui_actions_shared", value: sharedText),
                        .setVariable(actionStatus, to: "Saved to localStorage")
                    ])
                    Button("Load local").variant(.secondary).onClick([
                        .localStorageGet(key: "wsui_actions_shared", into: storageEcho),
                        .setVariable(actionStatus, to: "Loaded from localStorage")
                    ])
                    Button("Save session").variant(.secondary).onClick([
                        .sessionStorageSet(key: "wsui_actions_shared", value: sharedText),
                        .setVariable(actionStatus, to: "Saved to sessionStorage")
                    ])
                    Button("Load session").variant(.secondary).onClick([
                        .sessionStorageGet(key: "wsui_actions_shared", into: storageEcho),
                        .setVariable(actionStatus, to: "Loaded from sessionStorage")
                    ])
                    Button("Copy text").outline(.primary).onClick(.clipboardCopy(sharedText))
                }.margin(.top, 8)
                
                Text("Storage echo: $0", storageEcho).font(.subtitle).padding(.top, 8)
                Text("Status: $0", actionStatus)
            }
            
            InteractiveBindingActionsSection(pageKey: "actions")
        }
    }

    var controller: String? = "controls"

    var method: String? = "actions"

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
