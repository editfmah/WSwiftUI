//
//  BaseWebEndpoint+Menu.swift
//  SWWebAppServer
//
//  Created by Adrian on 11/07/2025.
//

import Foundation

/// A single page entry in your nav
public struct MenuItemModel {
  public let title: String
  public let path: String
}

/// A top-level section containing those pages—or, if `items` is empty, a standalone link
public struct MenuSectionModel {
  public let title: String
  public let path: String?         // when non-nil, clicking the section title goes here
  public let items: [MenuItemModel]
}

public extension BaseWebEndpoint {
  
  /// Turn the raw `ephemeralData["menu"]` into a strongly-typed model.
  ///
  /// Expects `ephemeralData["menu"]` to be an array of tuples:
  ///   (primary: String, secondary: String?, path: String)
  /// where `secondary == nil` means “this primary has no children, so use `path` for the section itself.”
    var menuEntries: [MenuEntry] {
        guard let raw = ephemeralData["menu_data"]
                as? [MenuEntry]
        else { return [] }
        
        return raw
    }
}
