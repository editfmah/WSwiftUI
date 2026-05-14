import Foundation
import WSwiftUI

public extension CoreWebEndpoint {
    @discardableResult
    func DemoPage(title: String,
                  subtitle: String? = nil,
                  _ content: WebComposerClosure) -> WebElement {
        Template {
            VStack {
                Text(title).font(.largeTitle).bold().padding(.bottom, 8)
                if let subtitle {
                    Text(subtitle).padding(.bottom, 24)
                }
                content()
            }.padding(40)
        }
    }

    @discardableResult
    func DemoSection(_ title: String,
                     description: String? = nil,
                     code: String? = nil,
                     _ preview: WebComposerClosure) -> WebElement {
        Card {
            CardHeader {
                Text(title).font(.title2).bold()
            }
            CardBody {
                if let description {
                    Text(description).padding(.bottom, 12)
                }
                preview()
                if let code {
                    Text("Usage").font(.subtitle).bold().padding([.top, .bottom], 8)
                    Code(language: .swift, code)
                }
            }
        }.shadow().margin(.bottom, 24)
    }
    
    @discardableResult
    func InteractiveBindingActionsSection(pageKey: String) -> WebElement {
        let sharedText = WString("Live value for \(pageKey)").name("\(pageKey)_shared_text")
        let status = WString("Ready").name("\(pageKey)_status")
        let hidePanel = WBool(false).name("\(pageKey)_hide_panel")
        let progress = WInt(35).name("\(pageKey)_progress")
        let panelId = "\(pageKey)_binding_actions_panel"
        
        _ = sharedText.onValueChanged([
            .setVariable(status, to: "Shared text changed")
        ])
        _ = hidePanel.onValueChanged([
            .setVariable(status, to: "Visibility state changed")
        ])
        
        return DemoSection(
            "Bindings + Actions Playground",
            description: "Multiple controls are bound to the same variable, and button actions update, hide, fade, and animate bound elements.",
            code: """
let sharedText = WString("Live value").name("shared_text")
let hidePanel = WBool(false).name("hide_panel")
let progress = WInt(35).name("progress")

TextField("Input A", text: sharedText)
TextField("Input B", text: sharedText)
TextArea("Mirror", text: sharedText)
Text("Shared output: $0", sharedText)

Button("Toggle hidden bool").onClick(.toggle(hidePanel))
Button("Fade panel").onClick(.fadeToggle(ref: "panelId", duration: 0.25))
"""
        ) {
            Toggle("Hide panel through bound bool", isOn: hidePanel)
                .margin(.bottom, 12)
            
            HStack(spacing: 8) {
                Button("Preset A")
                    .variant(.secondary)
                    .onClick([
                        .setVariable(sharedText, to: "Preset A"),
                        .setVariable(status, to: "Preset A applied")
                    ])
                Button("Preset B")
                    .variant(.secondary)
                    .onClick([
                        .setVariable(sharedText, to: "Preset B"),
                        .setVariable(status, to: "Preset B applied")
                    ])
                Button("Toggle hidden")
                    .variant(.warning)
                    .onClick(.toggle(hidePanel))
                Button("Fade panel")
                    .variant(.dark)
                    .onClick(.fadeToggle(ref: panelId, duration: 0.25))
                Button("Pulse panel")
                    .outline(.primary)
                    .onClick(.addClassFor(ref: panelId, className: "shadow-lg", durationMs: 700))
            }.margin(.bottom, 12)
            
            Card {
                CardHeader {
                    Text("Shared variable controls").bold()
                }
                CardBody {
                    Text("Status: $0", status).font(.subtitle).padding(.bottom, 8)
                    TextField("Input A", text: sharedText, prompt: "Type once")
                    TextField("Input B", text: sharedText, prompt: "Same variable")
                    TextArea("Textarea mirror", text: sharedText, prompt: "Still the same variable")
                        .rows(3)
                        .margin(.top, 8)
                    Text("Formatted output: $0", sharedText)
                        .font(.subtitle)
                        .padding(.top, 8)
                    
                    HStack(spacing: 8) {
                        Button("10%").variant(.secondary).onClick(.setVariable(progress, to: 10))
                        Button("45%").variant(.secondary).onClick(.setVariable(progress, to: 45))
                        Button("80%").variant(.secondary).onClick(.setVariable(progress, to: 80))
                    }.padding(.top, 12)
                    
                    Progress {
                        ProgressBar(progress, max: 100, variant: .success, striped: true, animated: true)
                    }.margin(.top, 8)
                }
            }
            .id(panelId)
            .hidden(hidePanel)
        }
    }
}
