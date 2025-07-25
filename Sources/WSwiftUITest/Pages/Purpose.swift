//
//  Purpose.swift
//  SWWebAppServer
//
//  Created by Adrian on 12/07/2025.
//

import Foundation
import WSwiftUI

class PurposePage : BaseWebEndpoint, WebEndpoint, WebContentEndpoint, MenuIndexable {
    
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
    
    var authenticationRequired: Bool = false
    
    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
    
}
