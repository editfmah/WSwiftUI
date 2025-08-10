//
//  Controls.swift
//  SWWebAppServer
//
//  Created by Adrian on 12/07/2025.
//

import Foundation
import WSwiftUI

class ControlsPage : CoreWebEndpoint, WebEndpoint, WebContentEndpoint, MenuIndexable {
    
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]
    
    var menuPrimary: String = "Controls"
    
    var menuSecondary: String?
    
    
    override func content() -> Any? {
        
        Template {
            
            Jumbotron {
                JumbotronTitle("Supported Controls")
            }
            
            VStack {
                
                Text("Form input controls:").font(.title)
                Form(action: self.path) {
                    HStack {
                        VStack {
                            //Text("Combo:")
                            let wVar = WString("op2").name("web_var_1")
                            let hide = WBool(false)
                            TextField(binding: wVar).type(.text).name("text_input_1").placeholder("placehodler text").label("Text Input")
                            Picker(type: .combo, binding: wVar) {
                                Text("Option 1").value("op1")
                                Text("Option 2").value("op2")
                                Text("Option 3").value("op3")
                            }.name("combo_1").label("Combo input").hidden(hide)
                            Button("Save").variant(.primary).type("SUBMIT")
                            TextField(binding: wVar).type(.text).name("text_input_2").placeholder("another placeholder text").label("Second text input")
                            Button("Set Value").variant(.secondary).onClick([
                                .setVariable(wVar, to: "op2")
                            ])
                            Button("Hide Combo").variant(.info).onClick([
                                .setVariable(hide, to: true)
                            ])
                            Toggle(value: hide).label("Hide the combo!")
                            HStack {
                                VStack {
                                    Picker(type: .radio(.horizontal), binding: wVar) {
                                        Text("Option 1").value("op1")
                                        Text("Option 2").value("op2")
                                        Text("Option 3").value("op3")
                                    }
                                }
                            }
                            HStack {
                                VStack {
                                    Picker(type: .segmented(.primary), binding: wVar) {
                                        Text("Option 1").value("op1")
                                        Text("Option 2").value("op2")
                                        Text("Option 3").value("op3")
                                    }
                                }
                            }
                        }
                    }
                }
                
            }.padding(80)
            
        }
        
    }
    
    override func save() -> Any? {
        return redirect(self.path)
    }
    
    var controller: String? = "controls"
    
    var method: String? = nil
    
    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
    
}
