//
//  Controls.swift
//  SWWebAppServer
//
//  Created by Adrian on 12/07/2025.
//

import Foundation
import WSwiftUI

class ControlsPage : CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]
    
    var menuPrimary: String = "Controls"
    
    var menuSecondary: String?
    
    
    override func content() -> Any? {
        
        Template {
            
            Jumbotron {
                JumbotronTitle("Supported Controls")
            }
            
            VStack {
                
                Callout(.primary) {
                    Text("This page demonstrates various form input controls available in WSwiftUI.")
                }
                
                Text("Form input controls:").font(.title)
                Form(action: self.path) {
                    HStack {
                        VStack {
                            Form {
                                let wVar = WString("op2").name("name")
                                TextField(binding: wVar).type(.text).placeholder("placehodler text").label("Text Input").validate([.notEmpty,.atLeast(6)])
                                Button("Save").variant(.primary).type("SUBMIT")
                            }
                        }
                    }
                }
                
                HStack {
                    FileUploader(action: "/api/controls") {
                        Text("Drop Files Here")
                            .font(.title2)
                            .foreground(.lightgrey)
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
