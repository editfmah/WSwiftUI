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
                            Text("Combo:")
                            let wVar = WString("zzz").name("web_var_1")
                            Picker(type: .combo, binding: wVar) {
                                Text("Option 1").value("op1")
                                Text("Option 2").value("op2")
                                Text("Option 3").value("op3")
                            }.name("combo_1")
                            Button("Save").variant(.primary).type("SUBMIT")
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
