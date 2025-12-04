//
//  Image.swift
//  SWWebAppServer
//
//  Created by Adrian on 05/07/2025.
//
import Foundation

public class WebImageElement: WebElement {}

public extension WebImageElement {

    /// Adds Bootstrap’s `.img-fluid` class
    @discardableResult
    func responsive() -> Self {
        addAttribute(.class("img-fluid"))
        return self
    }

    /// Adds Bootstrap’s `.img-thumbnail` class
    @discardableResult
    func thumbnail() -> Self {
        addAttribute(.class("img-thumbnail"))
        return self
    }

    /// Adds a `rounded` class
    @discardableResult
    func rounded() -> Self {
        addAttribute(.class("rounded"))
        return self
    }
    
    /// Enables native lazy-loading (`loading="lazy"`)
    @discardableResult
    func lazyLoad() -> Self {
        addAttribute(.custom("loading=\"lazy\""))
        return self
    }

    /// Sets object-fit via inline style
    @discardableResult
    func objectFit(_ fit: String) -> Self {
        // e.g. "cover", "contain", etc.
        addAttribute(.style("object-fit: \(fit);"))
        return self
    }
    
    /// reload the contents of the image every x seconds
    @discardableResult
    func reloadImage(seconds: Double) -> Self {
        // Clamp to a minimum interval to avoid 0 or negative values
        let clampedSeconds = max(seconds, 0.1)
        let intervalMs = Int(clampedSeconds * 1000)
        let id = self.builderId

        let js = """
        (function() {
            function setup() {
                var els = document.getElementsByClassName("\(id)");
                if (!els || !els.length) { return; }
                var img = els[0];

                // Clear any existing interval attached to this image
                if (img && img.dataset && img.dataset.reloadIntervalId) {
                    try { clearInterval(Number(img.dataset.reloadIntervalId)); } catch (e) {}
                }

                function reload() {
                    if (!img) { return; }
                    var src = img.getAttribute('src') || '';
                    try {
                        var url = new URL(src, window.location.href);
                        url.searchParams.set('_ts', Date.now().toString());
                        img.src = url.toString();
                    } catch (e) {
                        // Fallback: simple cache-buster if URL constructor fails
                        var sep = src.indexOf('?') === -1 ? '?' : '&';
                        img.src = src + sep + '_ts=' + Date.now();
                    }
                }

                var id = setInterval(reload, \(intervalMs));
                if (img && img.dataset) {
                    img.dataset.reloadIntervalId = String(id);
                }
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', setup, { once: true });
            } else {
                setup();
            }
        })();
        """

        addAttribute(.script(js))
        return self
    }
}


public extension CoreWebEndpoint {
    
    fileprivate func create(_ init: (_ element: WebImageElement) -> Void) -> WebImageElement {
        
        let element = WebImageElement()
        populateCreatedObject(element)
        `init`(element)
        return element
        
    }
    
    @discardableResult
    func Image(_ src: String, alt: String = "") -> WebImageElement {
        let img: WebImageElement = create { el in
            el.elementName = "img"
            el.class(el.builderId)       // so we can target it via JS/CSS if needed
            el.src(src)
            if !alt.isEmpty { el.alt(alt) }
        }
        return img
    }
}

