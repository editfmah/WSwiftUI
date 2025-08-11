//
//  controls-test.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 10/08/2025.
//

import Foundation
import WSwiftUI

class ControlsAPI : CoreWebEndpoint, WebEndpoint, WebApiEndpoint {
    
    func call() -> Any? {
        // This is a test API endpoint that returns a simple message
        if let request = data.webVariabileMessage() {
            request.data["c58846449658"] = .bool(true)
            return request
        }
        return HttpResponse.internalServerError
    }
    
    func acceptedRoles() -> [String]? {
        return []
    }
    
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]
    var controller: String? = "api"
    var method: String? = "controls"
    
}
