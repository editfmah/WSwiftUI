//
//  WebAction.swift
//  SWWebAppServer
//
//  Created by Adrian on 31/01/2025.
//

// permissions extensions
internal extension [String] {
    func containsAll(_ collection: [String]) -> Bool {
        for item in collection {
            if !self.contains(item) {
                return false
            }
        }
        return true
    }
    func containsAny(_ collection: [String]) -> Bool {
        for item in collection {
            if self.contains(item) {
                return true
            }
        }
        return false
    }
}

public enum WebRequestActivity : String, Codable {
    
    case Content = "content"
    case Persist = "persist"
    
    static func from(string: String, `default`: WebRequestActivity? = nil) -> WebRequestActivity {
        return WebRequestActivity.init(rawValue: string) ?? `default` ?? .Content
    }
    
    static func from(request: HttpRequest) -> WebRequestActivity {
        
        var action: WebRequestActivity = .Content
        
        switch request.head.method {
            case .GET:
                action = .Content
            case .POST:
                action = .Persist
            case .PUT:
                action = .Persist
            case .DELETE:
                action = .Persist
            case .PATCH:
                action = .Persist
            case .HEAD:
                action = .Content
            default:
                action = .Content
        }
        
        return action
        
    }
    
}
