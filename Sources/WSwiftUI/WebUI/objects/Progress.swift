//
//  Progress.swift
//  SWWebAppServer
//
//  Created by Adrian on 07/07/2025.
//

import Foundation

// 1) Dedicated subclasses for Progress container and bars
public class WebProgressElement: WebCoreElement {}
public class WebProgressBarElement: WebCoreElement {}


// 3) Fluent modifiers for Progress container
public extension WebProgressElement {
    /// Adds a height (e.g. "height: 1rem;")
    @discardableResult
    func height(_ cssValue: String) -> Self {
        addAttribute(.style("height: \(cssValue)"))
        return self
    }

    /// Enables stacking multiple bars (no extra class needed)
    @discardableResult
    func stackable() -> Self {
        return self
    }
}

// 4) Fluent modifiers for ProgressBar
public extension WebProgressBarElement {

    /// Sets aria-min and aria-max
    @discardableResult
    func range(min: Int = 0, max: Int = 100) -> Self {
        addAttribute(.custom("aria-valuemin=\"\(min)\""))
        addAttribute(.custom("aria-valuemax=\"\(max)\""))
        return self
    }

    /// Applies a contextual background (e.g. bg-success)
    @discardableResult
    func variant(_ variant: BootstrapVariant) -> Self {
        addAttribute(.variant(variant))
        addAttribute(.class("bg-\(variant.rawValue)"))
        return self
    }

    /// Applies striped styling
    @discardableResult
    func striped(_ on: Bool = true) -> Self {
        if on {
            addAttribute(.class("progress-bar-striped"))
        }
        return self
    }

    /// Animates stripes
    @discardableResult
    func animated(_ on: Bool = true) -> Self {
        if on {
            addAttribute(.class("progress-bar-animated"))
        }
        return self
    }
}

// 5) DSL factories on BaseWebEndpoint
public extension CoreWebEndpoint {
    /// Creates a <div class="progress"> container
    @discardableResult
    func Progress(_ content: WebComposerClosure) -> WebProgressElement {
        let progress = WebProgressElement()
        populateCreatedObject(progress)
        progress.elementName = "div"
        progress.addAttribute(.class("progress"))
        stack.append(progress)
        content()
        stack.removeAll(where: { $0.builderId == progress.builderId })
        return progress
    }

    /// Static progress bar with given value
    @discardableResult
    func ProgressBar(value: Int,
                     max: Int = 100,
                     variant: BootstrapVariant? = nil,
                     striped: Bool = false,
                     animated: Bool = false) -> WebProgressBarElement {
        guard let _ = stack.last as? WebProgressElement else {
            fatalError("ProgressBar must be used inside Progress { ... } block")
        }
        let bar = WebProgressBarElement()
        populateCreatedObject(bar)
        bar.elementName = "div"
        bar.addAttribute(.class("progress-bar"))
        bar.addAttribute(.pair("role", "progressbar"))
        bar.width(value)
        bar.range(min: 0, max: max)
        if let v = variant { bar.variant(v) }
        if striped { bar.striped() }
        if animated { bar.animated() }
        return bar
    }

    /// Dynamic progress bar bound to an Int variable
    @discardableResult
    func ProgressBar(_ variable: WebVariableElement,
                     max: Int = 100,
                     variant: BootstrapVariant? = nil,
                     striped: Bool = false,
                     animated: Bool = false) -> WebProgressBarElement {
        guard let _ = stack.last as? WebProgressElement else {
            fatalError("Bound ProgressBar must be inside Progress { ... } block")
        }
        // create bar
        let bar = WebProgressBarElement()
        populateCreatedObject(bar)
        bar.elementName = "div"
        bar.addAttribute(.class("progress-bar"))
        bar.addAttribute(.pair("role", "progressbar"))
        // assign id for DOM updates
        let barId = "progressBar_\(bar.builderId)"
        bar.id(barId)
        // initial width from variable
        let initial = variable.asInt()
        bar.width(initial)
        bar.range(min: 0, max: max)
        if let v = variant { bar.variant(v) }
        if striped { bar.striped() }
        if animated { bar.animated() }
        // script to update width on variable change
        bar.addAttribute(.script("""
var _lastVal_\(bar.builderId) = \(initial);
setInterval(function() {
  var val = \(variable.builderId);
  if (val !== _lastVal_\(bar.builderId)) {
    var pct = Math.min(Math.max(val, 0), \(max)) / \(max) * 100;
    var el = document.getElementById('\(barId)');
    if (el) {
      el.style.width = pct + '%';
      el.setAttribute('aria-valuenow', val);
    }
    _lastVal_\(bar.builderId) = val;
  }
}, 500);
"""))
        return bar
    }

    /// Dynamic progress bar bound to a Double variable
    @discardableResult
    func ProgressBar(_ variable: WebVariableElement,
                     max: Double,
                     variant: BootstrapVariant? = nil,
                     striped: Bool = false,
                     animated: Bool = false) -> WebProgressBarElement {
        guard let _ = stack.last as? WebProgressElement else {
            fatalError("Bound ProgressBar must be inside Progress { ... } block")
        }
        let bar = WebProgressBarElement()
        populateCreatedObject(bar)
        bar.elementName = "div"
        bar.addAttribute(.class("progress-bar"))
        bar.addAttribute(.pair("role", "progressbar"))
        let barId = "progressBar_\(bar.builderId)"
        bar.id(barId)
        // initial width from variable
        let initial = variable.asDouble()
        let initPct = Int((initial / max) * 100)
        bar.width(initPct)
        bar.range(min: 0, max: Int(max))
        if let v = variant { bar.variant(v) }
        if striped { bar.striped() }
        if animated { bar.animated() }
        bar.addAttribute(.script("""
var _lastVal_\(bar.builderId) = \(initial);
setInterval(function() {
  var val = \(variable.builderId);
  if (val !== _lastVal_\(bar.builderId)) {
    var pct = Math.min(Math.max(val, 0), \(max)) / \(max) * 100;
    var el = document.getElementById('\(barId)');
    if (el) {
      el.style.width = pct + '%';
      el.setAttribute('aria-valuenow', val);
    }
    _lastVal_\(bar.builderId) = val;
  }
}, 500);
"""))
        return bar
    }
}
