//
//  WebCoreElementProperties.swift
//
//
//  Created by Adrian Herridge on 18/02/2024.
//

import Foundation

public enum WebStyle : String {
    
    case primary
    case secondary
    case success
    case danger
    case warning
    case info
    case light
    case dark
    case link
    case transparent
    
    static var all: [WebStyle] {
        return [.primary, .secondary, .success, .danger, .warning, .info, .light, .dark, .link, .transparent]
    }
    
    var textStyleClass: String {
        switch self {
        case .primary:
            return "text-primary"
        case .secondary:
            return "text-secondary"
        case .success:
            return "text-success"
        case .danger:
            return "text-danger"
        case .warning:
            return "text-warning"
        case .info:
            return "text-info"
        case .light:
            return "text-light"
        case .dark:
            return "text-dark"
        case .link:
            return "text-link"
        case .transparent:
            return "text-transparent"
        }
    }
    
    var buttonStyleClass: String {
        switch self {
        case .primary:
            return "btn-primary"
        case .secondary:
            return "btn-secondary"
        case .success:
            return "btn-success"
        case .danger:
            return "btn-danger"
        case .warning:
            return "btn-warning"
        case .info:
            return "btn-info"
        case .light:
            return "btn-light"
        case .dark:
            return "btn-dark"
        case .link:
            return "btn-link"
        case .transparent:
            return "btn-transparent"
        }
    }
    
    var linkStyleClass: String {
        switch self {
        case .primary:
            return "link-primary"
        case .secondary:
            return "link-secondary"
        case .success:
            return "link-success"
        case .danger:
            return "link-danger"
        case .warning:
            return "link-warning"
        case .info:
            return "link-info"
        case .light:
            return "link-light"
        case .dark:
            return "link-dark"
        case .link:
            return "link-link"
        case .transparent:
            return "link-transparent"
        }
    }
}

public struct BackgroundVideoOptions {
    var loop: Bool = true
    var muted: Bool = true
    var autoplay: Bool = true
    var controls: Bool = false
    var poster: String? = nil
    var videoType: String = "video/mp4"
}

public extension String {
    /// Converts “CamelCase” or “PascalCase” into “kebab-case”
    func insertDashes() -> String {
        var result = ""
        for char in self {
            if char.isUppercase {
                // start a new segment
                result.append("-")
                // append the lowercase form of this character
                result.append(contentsOf: String(char).lowercased())
            } else {
                result.append(char)
            }
        }
        // Trim any leading/trailing dash
        return result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}


public enum Operator {
    
    case equals(Any)
    case isEmpty
    case isZero
    case isNonzero
    case isNotEmpty
    case isTrue
    case isFalse
    case isPositive
    case isNegative
    
    var javascriptCondition: String {
        get {
            switch self {
            case .equals(let comparitor):
                if let stringValue = comparitor as? String {
                    return "== '\(stringValue)'"
                } else if let intValue = comparitor as? Int {
                    return "== \(intValue)"
                } else if let doubleValue = comparitor as? Double {
                    return "== \(doubleValue)"
                } else if let boolValue = comparitor as? Bool {
                    return "== \(boolValue ? "true" : "false")"
                } else {
                    return "== '\(comparitor)'"
                }
            case .isEmpty:
                return "== ''"
            case .isNotEmpty:
                return "!= ''"
            case .isTrue:
                return "== true"
            case .isFalse:
                return "== false"
            case .isZero:
                return "== 0"
            case .isNonzero:
                return "!= 0"
            case .isPositive:
                return "> 0"
            case .isNegative:
                return "< 0"
            }
        }
    }
    
}

// Define BadgeStyle enum
public enum BadgeStyle: String {
    case primary = "bg-primary"
    case secondary = "bg-secondary"
    case success = "bg-success"
    case danger = "bg-danger"
    case warning = "bg-warning"
    case info = "bg-info"
    case light = "bg-light"
    case dark = "bg-dark"
}

public enum WebAreaPosition {
    case leading
    case trailing
    case top
    case bottom
    case all
}

public enum WebCornerPosition : String {
    case topLeft = "TopLeft"
    case topRight = "TopRight"
    case bottomLeft = "BottomLeft"
    case bottomRight = "BottomRight"
}

public enum WebFontSize {
    case veryLargeTitle
    case largeTitle
    case title
    case title2
    case normal
    case subtitle
    case caption
    case footnote
    case custom(_ size: Int)
}

public enum WebOpacity {
    
    case opaque
    case semiOpaque
    case semiTransparent
    case nearTransparent
    case clear
    
    var bsValue: String {
        switch self {
        case .opaque:
            return "100"
        case .semiOpaque:
            return "75"
        case .semiTransparent:
            return "50"
        case .nearTransparent:
            return "25"
        case .clear:
            return "0"
        }
    }
    
    var cssValue: String {
        switch self {
        case .opaque:
            return "1"
        case .semiOpaque:
            return "0.75"
        case .semiTransparent:
            return "0.5"
        case .nearTransparent:
            return "0.25"
        case .clear:
            return "0"
        }
    }
    
}

public enum WebColor {
    
    case red
    case darkred
    case lightred
    case green
    case lightgreen
    case darkgreen
    case blue
    case lightblue
    case darkblue
    case yellow
    case lightyellow
    case darkyellow
    case orange
    case lightorange
    case darkorange
    case purple
    case lightpurple
    case darkpurple
    case pink
    case lightpink
    case darkpink
    case brown
    case lightbrown
    case darkbrown
    case grey
    case darkGrey
    case lightGrey
    case indigo
    case lightindigo
    case darkindigo
    case teal
    case lightteal
    case darkteal
    case cyan
    case lightcyan
    case darkcyan
    case black
    case white
    case transparent
    case custom(_ hexColor: String)
    
    var bsColor: String {
        switch self {
        case .red,. darkred, .lightred:
            return "danger"
        case .green, .lightgreen, .darkgreen:
            return "success"
        case .blue, .lightblue, .darkblue:
            return "primary"
        case .yellow, .lightyellow, .darkyellow:
            return "warning"
        case .orange, .lightorange, .darkorange:
            return "warning"
        case .purple, .lightpurple, .darkpurple:
            return "info"
        case .pink, .lightpink, .darkpink:
            return "danger"
        case .brown, .lightbrown, .darkbrown:
            return "secondary"
        case .grey:
            return "secondary"
        case .lightGrey:
            return "light"
        case .darkGrey:
            return "dark"
        case .indigo, .lightindigo, .darkindigo:
            return "primary"
        case .teal, .lightteal, .darkteal:
            return "info"
        case .cyan, .lightcyan, .darkcyan:
            return "info"
        case .black:
            return "dark"
        case .white:
            return "white"
        case .transparent:
            return "transparent"
        case .custom(_):
            return "custom"
        }
    }
    
    var rgba: String {
        switch self {
        case .red:
            return "rgba(255,0,0,1)"
        case .darkred:
            return "rgba(139,0,0,1)"
        case .lightred:
            return "rgba(255,102,102,1)"
        case .green:
            return "rgba(0,128,0,1)"
        case .lightgreen:
            return "rgba(102,255,102,1)"
        case .darkgreen:
            return "rgba(0,100,0,1)"
        case .blue:
            return "rgba(0,0,255,1)"
        case .lightblue:
            return "rgba(102,102,255,1)"
        case .darkblue:
            return "rgba(0,0,139,1)"
        case .yellow:
            return "rgba(255,255,0,1)"
        case .lightyellow:
            return "rgba(255,255,102,1)"
        case .darkyellow:
            return "rgba(255,255,0,1)"
        case .orange:
            return "rgba(255,165,0,1)"
        case .lightorange:
            return "rgba(255,204,153,1)"
        case .darkorange:
            return "rgba(255,140,0,1)"
        case .purple:
            return "rgba(128,0,128,1)"
        case .lightpurple:
            return "rgba(204,153,255,1)"
        case .darkpurple:
            return "rgba(75,0,130,1)"
        case .pink:
            return "rgba(255,192,203,1)"
        case .lightpink:
            return "rgba(255,204,204,1)"
        case .darkpink:
            return "rgba(255,105,180,1)"
        case .brown:
            return "rgba(165,42,42,1)"
        case .lightbrown:
            return "rgba(210,180,140,1)"
        case .darkbrown:
            return "rgba(139,69,19,1)"
        case .grey:
            return "rgba(128,128,128,1)"
        case .darkGrey:
            return "rgba(64,64,64,1)"
        case .lightGrey:
            return "rgba(192,192,192,1)"
        case .indigo:
            return "rgba(75,0,130,1)"
        case .lightindigo:
            return "rgba(153,102,255,1)"
        case .darkindigo:
            return "rgba(75,0,130,1)"
        case .teal:
            return "rgba(0,128,128,1)"
        case .lightteal:
            return "rgba(102,255,255,1)"
        case .darkteal:
            return "rgba(0,139,139,1)"
        case .cyan:
            return "rgba(0,255,255,1)"
        case .lightcyan:
            return "rgba(102,255,255,1)"
        case .darkcyan:
            return "rgba(0,139,139,1)"
        case .black:
            return "rgba(0,0,0,1)"
        case .white:
            return "rgba(255,255,255,1)"
        case .transparent:
            return "rgba(0,0,0,0)"
        case .custom(let colorString):
            return colorString
        }
    
    }
    
    var hex: String {
        switch self {
        case .red:
            return "#FF0000"
        case .darkred:
            return "#8B0000"
        case .lightred:
            return "#FF6666"
        case .green:
            return "#008000"
        case .lightgreen:
            return "#66FF66"
        case .darkgreen:
            return "#006400"
        case .blue:
            return "#0000FF"
        case .lightblue:
            return "#6666FF"
        case .darkblue:
            return "#00008B"
        case .yellow:
            return "#FFFF00"
        case .lightyellow:
            return "#FFFF66"
        case .darkyellow:
            return "#FFFF00"
        case .orange:
            return "#FFA500"
        case .lightorange:
            return "#FFCC99"
        case .darkorange:
            return "#FF8C00"
        case .purple:
            return "#800080"
        case .lightpurple:
            return "#CC99FF"
        case .darkpurple:
            return "#4B0082"
        case .pink:
            return "#FFC0CB"
        case .lightpink:
            return "#FFCCCC"
        case .darkpink:
            return "#FF69B4"
        case .brown:
            return "#A52A2A"
        case .lightbrown:
            return "#D2B48C"
        case .darkbrown:
            return "#8B4513"
        case .grey:
            return "#808080"
        case .darkGrey:
            return "#404040"
        case .lightGrey:
            return "#C0C0C0"
        case .indigo:
            return "#4B0082"
        case .lightindigo:
            return "#9966FF"
        case .darkindigo:
            return "#4B0082"
        case .teal:
            return "#008080"
        case .lightteal:
            return "#66FFFF"
        case .darkteal:
            return "#008B8B"
        case .cyan:
            return "#00FFFF"
        case .lightcyan:
            return "#66FFFF"
        case .darkcyan:
            return "#008B8B"
        case .black:
            return "#000000"
        case .white:
            return "#FFFFFF"
        case .transparent:
            return "#000000"
        case .custom(let colorString):
            return colorString
        }
    }
}

public enum WebGradientDirection: String {
    case toTop = "to top"
    case toBottom = "to bottom"
    case toLeft = "to left"
    case toRight = "to right"
    case toTopLeft = "to top left"
    case toTopRight = "to top right"
    case toBottomLeft = "to bottom left"
    case toBottomRight = "to bottom right"
}

public enum WebMarginType {
    case auto
    case none
}

public enum WebTextAlignment: String {
    case left
    case right
    case center
    case justify
}

public enum WebContentAlignment : String {
    case left
    case right
    case middle
    case top
    case bottom
    case center
}

// html properties for html style `text-wrap`
public enum WebTextWrapType : String {
    case auto
    case balance
    case nowrap
    case wrap
    case stable
}

public enum WebPosition : String {
    case relative
    case absolute
    case fixed
    case sticky
}

public enum WebBackgroundSize: String {
    case auto
    case cover
    case contain
}

public enum WebBackgroundRepeat: String {
    case noRepeat = "no-repeat"
    case `repeat` = "repeat"
    case repeatX = "repeat-x"
    case repeatY = "repeat-y"
}

public enum WebBackgroundPosition: String {
    case topLeft = "top left"
    case topCenter = "top center"
    case topRight = "top right"
    case centerLeft = "center left"
    case centerCenter = "center center"
    case centerRight = "center right"
    case bottomLeft = "bottom left"
    case bottomCenter = "bottom center"
    case bottomRight = "bottom right"
}

public enum WebPositionType: String {
    case `static` = "position-static"
    case relative = "position-relative"
    case absolute = "position-absolute"
    case fixed = "position-fixed"
    case sticky = "sticky-top"
    case stickyBottom = "sticky-bottom"
}

public enum WebPositionValue {
    case auto
    case pixels(Int)
    case percent(Int)
    
    var classValue: String {
        switch self {
        case .auto:
            return "auto"
        case .pixels(let value):
            return "\(value)px"
        case .percent(let value):
            return "\(value)%"
        }
    }
    
    var classSuffix: String {
        switch self {
        case .auto:
            return "auto"
        case .pixels(let value):
            return "\(value)"
        case .percent(let value):
            return "\(value)"
        }
    }
}

public enum WebTranslateDirection: String {
    case middle = "translate-middle"
    case x = "translate-middle-x"
    case y = "translate-middle-y"
}


public extension WebElement {
    
    // MARK: – Sizing
    
    @discardableResult
    func width(_ width: Int) -> Self {
        addAttribute(.style("width: \(width)px"))
        return self
    }
    
    @discardableResult
    func height(_ height: Int) -> Self {
        addAttribute(.style("height: \(height)px"))
        return self
    }
    
    @discardableResult
    func maxWidth(_ width: Int) -> Self {
        addAttribute(.style("max-width: \(width)px"))
        return self
    }
    
    @discardableResult
    func maxHeight(_ height: Int) -> Self {
        addAttribute(.style("max-height: \(height)px"))
        return self
    }
    
    @discardableResult
    func minWidth(_ width: Int) -> Self {
        addAttribute(.style("min-width: \(width)px"))
        return self
    }
    
    @discardableResult
    func minHeight(_ height: Int) -> Self {
        addAttribute(.style("min-height: \(height)px"))
        return self
    }
    
    
    // MARK: – Margin & Padding
    
    @discardableResult
    func margin(_ margin: Int) -> Self {
        addAttribute(.style("margin: \(margin)px"))
        return self
    }
    
    @discardableResult
    func margin(_ position: WebAreaPosition, _ margin: Int) -> Self {
        let prop: String
        switch position {
        case .leading:  prop = "margin-left"
        case .trailing: prop = "margin-right"
        case .top:      prop = "margin-top"
        case .bottom:   prop = "margin-bottom"
        case .all:      prop = "margin"
        }
        addAttribute(.style("\(prop): \(margin)px"))
        return self
    }
    
    @discardableResult
    func margin(_ positions: [WebAreaPosition], _ margin: Int) -> Self {
        for pos in positions { _ = self.margin(pos, margin) }
        return self
    }
    
    @discardableResult
    func margin(_ type: WebMarginType) -> Self {
        let value = (type == .auto ? "auto" : "unset")
        addAttribute(.style("margin: \(value)"))
        return self
    }
    
    @discardableResult
    func padding(_ padding: Int) -> Self {
        addAttribute(.style("padding: \(padding)px"))
        return self
    }
    
    @discardableResult
    func padding(_ position: WebAreaPosition, _ padding: Int) -> Self {
        let prop: String
        switch position {
        case .leading:  prop = "padding-left"
        case .trailing: prop = "padding-right"
        case .top:      prop = "padding-top"
        case .bottom:   prop = "padding-bottom"
        case .all:      prop = "padding"
        }
        addAttribute(.style("\(prop): \(padding)px"))
        return self
    }
    
    @discardableResult
    func padding(_ positions: [WebAreaPosition], _ padding: Int) -> Self {
        for pos in positions { _ = self.padding(pos, padding) }
        return self
    }
    
    
    // MARK: – Borders & Radius
    
    @discardableResult
    func border(_ color: WebColor, width: Int) -> Self {
        addAttribute(.style("border: \(width)px solid \(color.rgba)"))
        return self
    }
    
    @discardableResult
    func border(_ position: WebAreaPosition, _ color: WebColor, width: Int) -> Self {
        let prop: String
        switch position {
        case .leading:  prop = "border-left"
        case .trailing: prop = "border-right"
        case .top:      prop = "border-top"
        case .bottom:   prop = "border-bottom"
        case .all:      prop = "border"
        }
        addAttribute(.style("\(prop): \(width)px solid \(color.rgba)"))
        return self
    }
    
    @discardableResult
    func border(_ positions: [WebAreaPosition], _ color: WebColor, width: Int) -> Self {
        for pos in positions { _ = border(pos, color, width: width) }
        return self
    }
    
    @discardableResult
    func radius(_ radius: Int) -> Self {
        addAttribute(.style("border-radius: \(radius)px"))
        return self
    }
    
    @discardableResult
    func radius(_ position: WebCornerPosition, _ radius: Int) -> Self {
        // e.g. position.rawValue == "TopLeft" → border-top-left-radius
        let cssProp = "border-\(position.rawValue.lowercased().insertDashes())-radius"
        addAttribute(.style("\(cssProp): \(radius)px"))
        return self
    }
    
    @discardableResult
    func radius(_ positions: [WebCornerPosition], _ radius: Int) -> Self {
        for pos in positions { _ = self.radius(pos, radius) }
        return self
    }
    
    
    // MARK: – Shadows
    
    @discardableResult
    func shadow(_ shadow: Int) -> Self {
        addAttribute(.style("box-shadow: 0px 0px \(shadow)px 0px rgba(0,0,0,0.75)"))
        return self
    }
    
    
    // MARK: – Alignment & Display
    
    @discardableResult
    func align(_ alignment: WebContentAlignment) -> Self {
        return align([alignment])
    }
    
    @discardableResult
    func align(_ alignments: [WebContentAlignment]) -> Self {
        for a in alignments {
            let cls: String
            switch a {
            case .left:   cls = "justify-content-start"
            case .right:  cls = "justify-content-end"
            case .center: cls = "justify-content-center"
            case .top:    cls = "align-content-start"
            case .bottom: cls = "align-content-end"
            case .middle: cls = "align-content-center"
            }
            addAttribute(.class(cls))
        }
        return self
    }
    
    @discardableResult
    func textalign(_ align: WebTextAlignment) -> Self {
        addAttribute(.style("text-align: \(align.rawValue)"))
        return self
    }
    
    @discardableResult
    func wrap(_ type: WebTextWrapType) -> Self {
        addAttribute(.style("text-wrap: \(type.rawValue)"))
        return self
    }
    
    @discardableResult
    func clip() -> Self {
        addAttribute(.style("clip-path: border-box"))
        return self
    }
    
    
    // MARK: – Typography
    
    @discardableResult
    func font(_ font: WebFontSize) -> Self {
        let size: Int = {
            switch font {
            case .veryLargeTitle: return 64
            case .largeTitle:     return 32
            case .title:          return 24
            case .title2:         return 20
            case .normal:         return 16
            case .subtitle:       return 14
            case .caption:        return 12
            case .footnote:       return 10
            case .custom(let s):  return s
            }
        }()
        addAttribute(.style("font-size: \(size)px"))
        return self
    }
    
    @discardableResult
    func fontfamily(_ family: String) -> Self {
        addAttribute(.style("font-family: \(family)"))
        return self
    }
    
    @discardableResult
    func bold() -> Self {
        addAttribute(.style("font-weight: bold"))
        return self
    }
    
    @discardableResult
    func lightweight() -> Self {
        addAttribute(.style("font-weight: lighter"))
        return self
    }
    
    @discardableResult
    func italic() -> Self {
        addAttribute(.style("font-style: italic"))
        return self
    }
    
    @discardableResult
    func strikethrough() -> Self {
        addAttribute(.style("text-decoration: line-through"))
        return self
    }
    
    @discardableResult
    func underline(_ value: Bool) -> Self {
        addAttribute(.style("text-decoration: \(value ? "underline" : "none")"))
        return self
    }
    
    
    // MARK: – Color & Opacity
    
    @discardableResult
    func foreground(_ color: WebColor) -> Self {
        addAttribute(.style("color: \(color.rgba)"))
        return self
    }
    
    @discardableResult
    func background(_ color: WebColor) -> Self {
        addAttribute(.style("background-color: \(color.rgba)"))
        return self
    }
    
    @discardableResult
    func opacity(_ opacity: Double) -> Self {
        addAttribute(.style("opacity: \(opacity)"))
        return self
    }
    
    
    // MARK: – Background Utilities
    
    @discardableResult
    func background(_ dir: WebGradientDirection, _ colors: [WebColor]) -> Self {
        let stops = colors.map(\.rgba).joined(separator: ",")
        addAttribute(.style("background-image: linear-gradient(\(dir.rawValue),\(stops))"))
        return self
    }
    
    @discardableResult
    func backgroundImage(_ url: String) -> Self {
        addAttribute(.style("background-image: url(\(url))"))
        return self
    }
    
    @discardableResult
    func backgroundSize(_ size: WebBackgroundSize) -> Self {
        addAttribute(.style("background-size: \(size.rawValue)"))
        return self
    }
    
    @discardableResult
    func backgroundRepeat(_ `repeat`: WebBackgroundRepeat) -> Self {
        addAttribute(.style("background-repeat: \(`repeat`.rawValue)"))
        return self
    }
    
    @discardableResult
    func backgroundPosition(_ pos: WebBackgroundPosition) -> Self {
        addAttribute(.style("background-position: \(pos.rawValue)"))
        return self
    }
    
    @discardableResult
    func backgroundAttachment(_ attachment: String) -> Self {
        addAttribute(.style("background-attachment: \(attachment)"))
        return self
    }
    
    
    // MARK: – Utility Classes
    
    @discardableResult
    func collapsible() -> Self {
        addAttribute(.class("collapse"))
        return self
    }
    
    @discardableResult
    func position(_ position: WebPositionType) -> Self {
        addAttribute(.class(position.rawValue))
        return self
    }
    
    @discardableResult
    func top(_ value: WebPositionValue) -> Self {
        addAttribute(.class("top-\(value.classSuffix)"))
        return self
    }
    
    @discardableResult
    func bottom(_ value: WebPositionValue) -> Self {
        addAttribute(.class("bottom-\(value.classSuffix)"))
        return self
    }
    
    @discardableResult
    func start(_ value: WebPositionValue) -> Self {
        addAttribute(.class("start-\(value.classSuffix)"))
        return self
    }
    
    @discardableResult
    func end(_ value: WebPositionValue) -> Self {
        addAttribute(.class("end-\(value.classSuffix)"))
        return self
    }
    
    @discardableResult
    func translate(_ direction: WebTranslateDirection) -> Self {
        addAttribute(.class(direction.rawValue))
        return self
    }
    
}




