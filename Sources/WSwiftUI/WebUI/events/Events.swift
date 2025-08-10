//
//  Events.swift
//  SWWebAppServer
//
//  Created by Adrian on 04/07/2025.
//

import Foundation

public extension CoreWebContent {
    // MARK: – Click Event

    @discardableResult
    func onClick(_ actions: [WebAction]) -> Self {
        let js = """
\(builderId).addEventListener('click', function() {
    \(compileActions(actions))
});
"""
        addAttribute(.script(js))
        return self
    }

    @discardableResult
    func onClick(_ action: WebAction) -> Self {
        return onClick([action])
    }

    // MARK: – Disable Event

    @discardableResult
    func onDisable(_ actions: [WebAction]) -> Self {
        let js = """
var lastDisableValue\(builderId) = false;
var disableInterval\(builderId) = setInterval(function() {
    if (\(builderId).disabled != lastDisableValue\(builderId)) {
        if (\(builderId).disabled) { \(builderId).onDisable(); }
        lastDisableValue\(builderId) = \(builderId).disabled;
    }
}, 500);
\(builderId).onDisable = function() {
    \(compileActions(actions))
};
"""
        addAttribute(.script(js))
        return self
    }

    @discardableResult
    func onDisable(_ action: WebAction) -> Self {
        return onDisable([action])
    }

    // MARK: – Mouse Leave Event

    @discardableResult
    func onMouseLeave(_ actions: [WebAction]) -> Self {
        let js = """
\(builderId).addEventListener('mouseleave', function() {
    \(compileActions(actions))
});
"""
        addAttribute(.script(js))
        return self
    }

    @discardableResult
    func onMouseLeave(_ action: WebAction) -> Self {
        return onMouseLeave([action])
    }

    // MARK: – Mouse Over Event

    @discardableResult
    func onMouseover(_ actions: [WebAction]) -> Self {
        let js = """
\(builderId).addEventListener('mouseover', function() {
    \(compileActions(actions))
});
"""
        addAttribute(.script(js))
        return self
    }

    @discardableResult
    func onMouseover(_ action: WebAction) -> Self {
        return onMouseover([action])
    }
}
