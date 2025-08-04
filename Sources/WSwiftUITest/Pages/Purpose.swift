//
//  Purpose.swift
//  SWWebAppServer
//
//  Created by Adrian on 12/07/2025.
//

import Foundation
import WSwiftUI

class PurposePage : CoreWebEndpoint, WebEndpoint, WebContentEndpoint, MenuIndexable {
    
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]
    
    var menuPrimary: String = "Purpose"
    
    var menuSecondary: String?
    
    
    override func content() -> Any? {
        
        Template {
            
            Jumbotron {
                JumbotronTitle("Welcome to the Home Page")
                JumbotronSubtitle("This is a subtitle for the home page.")
            }
            
        }
        
    }
    
    var controller: String? = "purpose"
    
    var method: String? = nil
      
    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
    
}
