//
//  WebEndpoint+Path.swift
//  SWWebAppServer
//
//  Created by Adrian on 31/01/2025.
//

import Foundation

public extension WebEndpoint {
        
        static func path(action: WebAction? = nil, resource: UUID? = nil, subResource: UUID? = nil, version: UUID? = nil, filter: [String: String]? = nil, fragment: String? = nil, returnUrl: String? = nil) -> String {
            
            var path = "/"
            
            if let controller = controller {
                path += "\(controller)"
            }
            
            if let method = method {
                path += "/\(method)"
            }
            
            // check if there are any params at all and if so, appent a "?"
            if action != nil || resource != nil || subResource != nil || version != nil || filter != nil || fragment != nil || returnUrl != nil {
                path += "?"
            }
            
            if let action = action {
                path += "action=\(action.rawValue)"
            }
            
            if let resource = resource {
                path += "&resource=\(resource)"
            }
            
            if let subResource = subResource {
                path += "&subResource=\(subResource)"
            }
            
            if let version = version {
                path += "&version=\(version)"
            }
            
            if let filter = filter {
                path += "&filter="
                // now excode the filter as a JSON string
                if let data = try? JSONSerialization.data(withJSONObject: filter, options: .prettyPrinted) {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        // now append but make sure the string is URL encoded
                        path += "\(jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                    }
                }
            }
            
            return path
            
        }
        
}


