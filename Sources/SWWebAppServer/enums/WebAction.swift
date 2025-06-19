//
//  WebAction.swift
//  SWWebAppServer
//
//  Created by Adrian on 31/01/2025.
//

public enum WebAction : String, Codable {
    case View = "view"
    case Modify = "modify"
    case New = "new"
    case Save = "save"
    case Content = "content"
    case Delete = "delete"
    case Raw = "raw"
    static func from(string: String) -> WebAction {
        return WebAction.init(rawValue: string) ?? .Content
    }
}
