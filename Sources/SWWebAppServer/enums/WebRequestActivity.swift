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
    
    case View = "view"
    case Modify = "modify"
    case New = "new"
    case Save = "save"
    case Content = "content"
    case Delete = "delete"
    case Raw = "raw"
    
    static func from(string: String, `default`: WebRequestActivity? = nil) -> WebRequestActivity {
        return WebRequestActivity.init(rawValue: string) ?? `default` ?? .Content
    }
    
    static func from(request: HttpRequest) -> WebRequestActivity {
        
        var action: WebRequestActivity = .Content
        
        switch request.method.lowercased() {
            case "get":
                action = .Content
            case "post":
                action = .Save
            case "put":
                action = .Save
            case "delete":
                action = .Delete
            case "patch":
                action = .Modify
            case "head":
                action = .Content
            default:
                action = .Content
        }
        
        // now see if these are overridden with a query param
        if let specified = request.queryparams["action"] {
            return WebRequestActivity.from(string: specified, default: action)
        }
        
        return action
        
    }
    
}
