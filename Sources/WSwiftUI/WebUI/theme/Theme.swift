//
//  Theme.swift
//
//
//  Created by Adrian Herridge on 01/06/2024.
//

import Foundation

public protocol Theme {
    
    // Colors
    var background: WebColor { get }
    var onBackground: WebColor { get }
    var menuBackground: WebColor { get }
    var onMenuBackground: WebColor { get }
    var accent: WebColor { get }
    var primary: WebColor { get }
    var onPrimary: WebColor { get }
    var secondary: WebColor { get }
    var onSecondary: WebColor { get }
    var tertiary: WebColor { get }
    var onTertiary: WebColor { get }
    
    // Font Family
    var fontFamily: String { get }
    var headingFontFamily: String { get }
    
}

