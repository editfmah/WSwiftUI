//
//  Actions.swift
//
//
//  Created by Adrian Herridge on 21/05/2024.
//

import Foundation
import CommonCrypto

import Foundation

extension String {
    /// Computes the MD5 hash of the UTF-8 representation of this string
    /// and returns the hex-encoded digest.
    var md5: String {
        // 1) Prepare message
        let message = Array(self.utf8)
        let messageLenBits = UInt64(message.count) * 8
        
        // append the bit '1' (0x80), then pad with zeros until length ≡ 448 mod 512
        var padded = message + [0x80]
        while ((padded.count * 8) % 512) != 448 {
            padded.append(0)
        }
        // append original length in bits as a 64-bit little-endian integer
        padded += messageLenBits.littleEndian.bytes
        
        // MD5 uses four 32-bit state variables
        var a0: UInt32 = 0x67452301
        var b0: UInt32 = 0xefcdab89
        var c0: UInt32 = 0x98badcfe
        var d0: UInt32 = 0x10325476
        
        // Constants for each operation: K[i] = floor(abs(sin(i+1)) * 2^32)
        let K: [UInt32] = (0..<64).map {
            UInt32(bitPattern: Int32((abs(sin(Double($0 + 1))) * Double(UInt32.max)).rounded()))
        }
        
        // Per-round shift amounts
        let s: [UInt32] = [
            7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
            5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
            4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
            6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
        ]
        
        // Process the message in successive 512-bit (64-byte) chunks
        for chunkStart in stride(from: 0, to: padded.count, by: 64) {
            // break chunk into sixteen 32-bit little-endian words M[j], 0 ≤ j < 16
            let chunk = Array(padded[chunkStart..<chunkStart+64])
            var M = [UInt32](repeating: 0, count: 16)
            for j in 0..<16 {
                let i = j * 4
                M[j] = UInt32(chunk[i]) |
                (UInt32(chunk[i+1]) << 8) |
                (UInt32(chunk[i+2]) << 16) |
                (UInt32(chunk[i+3]) << 24)
            }
            
            // Initialize per-chunk variables
            var A = a0, B = b0, C = c0, D = d0
            
            // Main loop
            for i in 0..<64 {
                var F: UInt32 = 0
                var g: Int = 0
                
                switch i {
                case  0..<16:
                    F = (B & C) | ((~B) & D)
                    g = i
                case 16..<32:
                    F = (D & B) | ((~D) & C)
                    g = (5*i + 1) % 16
                case 32..<48:
                    F = B ^ C ^ D
                    g = (3*i + 5) % 16
                default:
                    F = C ^ (B | (~D))
                    g = (7*i) % 16
                }
                
                let tmp = D
                D = C
                C = B
                B = B &+ leftRotate((A &+ F &+ K[i] &+ M[g]), by: s[i])
                A = tmp
            }
            
            // Add this chunk's hash to result so far
            a0 = a0 &+ A
            b0 = b0 &+ B
            c0 = c0 &+ C
            d0 = d0 &+ D
        }
        
        // Produce the final hash value (little-endian) as hex string
        let digest = [a0, b0, c0, d0].flatMap { word -> [UInt8] in
            let le = word.littleEndian
            return [
                UInt8(truncatingIfNeeded: le >> 0),
                UInt8(truncatingIfNeeded: le >> 8),
                UInt8(truncatingIfNeeded: le >> 16),
                UInt8(truncatingIfNeeded: le >> 24),
            ]
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Left-rotate a 32-bit integer by given number of bits
    private func leftRotate(_ x: UInt32, by: UInt32) -> UInt32 {
        return (x << by) | (x >> (32 - by))
    }
}

private extension UInt64 {
    /// Break a 64-bit integer into its 8 constituent bytes in little-endian
    var bytes: [UInt8] {
        return (0..<8).map {
            UInt8(truncatingIfNeeded: self >> (8 * $0))
        }
    }
}


public enum WebAction {
    case script(String)
    case load(ref: String? = nil, url: String)
    case navigate(String)
    case post(url: String? = nil, values: [WebVariableElement]? = nil, onSuccessful: [WebAction]? = nil, onFailed: [WebAction]? = nil, onTimeout: [WebAction]? = nil, resultInto: WebVariableElement? = nil)
    case setVariable(_ variable: WebVariableElement, to: Any?)
    case setInput(_ input: String, to: Any?)
    case setVariableName(_ varName: String, to: Any?)
    case addClass(String)
    case removeClass(String)
    case hidden(ref: String? = nil,_ value: Bool)
    case `if`(WebVariableElement, Operator, [WebAction], [WebAction]?)
    case toggle(WebVariableElement)
    case foregroundColor(ref: String? = nil,_ color: WebColor)
    case backgroundColor(ref: String? = nil,_ color: WebColor)
    // Background actions for elements
    case setBackgroundColor(ref: String? = nil, color: WebColor)
    case setBackgroundImage(ref: String? = nil, url: String)
    case setBackgroundVideo(ref: String? = nil, url: String, options: BackgroundVideoOptions?)
    // Background actions for the page
    case setPageBackgroundColor(color: WebColor)
    case setPageBackgroundImage(url: String)
    case setPageBackgroundVideo(url: String, options: BackgroundVideoOptions?)
    case underlineColor(ref: String? = nil,_ color: WebColor)
    case underline(ref: String? = nil,_ value: Bool)
    case bold(ref: String? = nil,_ value: Bool)
    case italic(ref: String? = nil,_ value: Bool)
    case strikethrough(ref: String? = nil,_ value: Bool)
    case fontSize(ref: String? = nil,_ size: Int)
    case fontFamily(ref: String? = nil,_ name: String)
    case fontWeight(ref: String? = nil,_ weight: String)
    case opacity(ref: String? = nil,_ value: Double)
    case random([WebAction])
    case showModal(ref: String, contentURL: String? = nil)
    case hideModal(ref: String)
    case collapse(ref: String)
    case popover(title: String, content: String)
    case showOffCanvas(ref: String)
    case hideOffCanvas(ref: String)
    case carouselNext(ref: String)
    case carouselPrev(ref: String)
    case carouselTo(ref: String, index: Int)
    case accordionToggle(ref: String)
    case progressSet(ref: String, value: Int)
    case spinnerSet(ref: String, type: SpinnerType, size: SpinnerSize, color: WebColor, label: String)
    // this response receives the body of the response from the post request, followed by the code, fillowed by the headers
    /*
     so the structure looks like function(body, code, headers) { /* your code goes here and you can access body, code, headers */ }
     */
    case handleResponse(script: String)
    case src(ref: String? = nil, url: String)
    case scrollTo(ref: String? = nil, behavior: ScrollBehavior, alignment: ScrollAlignment = .start)
    case addToArray(variable: WebVariableElement, value: String)
    case removeFromArray(variable: WebVariableElement, value: String)
    case toggleArray(variable: WebVariableElement, value: String)
    case fadeIn(ref: String? = nil, duration: Double)
    case fadeOut(ref: String? = nil, duration: Double)
    case fadeToggle(ref: String? = nil, duration: Double)
    
}

public func CompileActions(_ actions: [WebAction], builderId: String) -> String {
    var script = ""
    
    for action in actions {
        switch action {
            // Background actions for elements
        case .setBackgroundColor(let ref, let color):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.backgroundColor = '\(color.rgba)';\n"
            } else {
                script += "\(builderId).style.backgroundColor = '\(color.rgba)';\n"
            }
            
        case .setBackgroundImage(let ref, let url):
            if let ref = ref {
                script += """
                                var element = document.getElementById('\(ref)');
                                if (element) {
                                    element.style.backgroundImage = 'url(\(url))';
                                    element.style.backgroundSize = 'cover';
                                    element.style.backgroundRepeat = 'no-repeat';
                                    element.style.backgroundPosition = 'center';
                                }
                                """
            } else {
                script += """
                                \(builderId).style.backgroundImage = 'url(\(url))';
                                \(builderId).style.backgroundSize = 'cover';
                                \(builderId).style.backgroundRepeat = 'no-repeat';
                                \(builderId).style.backgroundPosition = 'center';
                                """
            }
            
        case .setBackgroundVideo(let ref, let url, let options):
            let opts = options ?? BackgroundVideoOptions()
            let loop = opts.loop ? "loop" : ""
            let muted = opts.muted ? "muted" : ""
            let autoplay = opts.autoplay ? "autoplay" : ""
            let controls = opts.controls ? "controls" : ""
            let poster = opts.poster != nil ? "poster='\(opts.poster!)'" : ""
            let videoType = opts.videoType
            
            // Create a unique identifier for the video element
            let videoId = "video_\(ref ?? builderId)"
            
            // Build the video element HTML
            let videoHTML = """
                            <video id="\(videoId)" class="background-video" \(autoplay) \(loop) \(muted) \(controls) \(poster)>
                                <source src="\(url)" type="\(videoType)">
                            </video>
                            """
            
            if let ref = ref {
                script += """
                                var element = document.getElementById('\(ref)');
                                if (element) {
                                    element.style.position = 'relative';
                                    element.insertAdjacentHTML('afterbegin', `\(videoHTML)`);
                                    var videoElement = document.getElementById('\(videoId)');
                                    videoElement.style.position = 'absolute';
                                    videoElement.style.top = '0';
                                    videoElement.style.left = '0';
                                    videoElement.style.width = '100%';
                                    videoElement.style.height = '100%';
                                    videoElement.style.objectFit = 'cover';
                                    videoElement.style.zIndex = '-1';
                                }
                                """
            } else {
                script += """
                                \(builderId).style.position = 'relative';
                                \(builderId).insertAdjacentHTML('afterbegin', `\(videoHTML)`);
                                var videoElement = document.getElementById('\(videoId)');
                                videoElement.style.position = 'absolute';
                                videoElement.style.top = '0';
                                videoElement.style.left = '0';
                                videoElement.style.width = '100%';
                                videoElement.style.height = '100%';
                                videoElement.style.objectFit = 'cover';
                                videoElement.style.zIndex = '-1';
                                """
            }
            
            // Background actions for the page
        case .setPageBackgroundColor(let color):
            script += """
                            document.body.style.backgroundColor = '\(color.rgba)';
                            """
            
        case .setPageBackgroundImage(let url):
            script += """
                            document.body.style.backgroundImage = 'url(\(url))';
                            document.body.style.backgroundSize = 'cover';
                            document.body.style.backgroundRepeat = 'no-repeat';
                            document.body.style.backgroundPosition = 'center';
                            """
            
        case .setPageBackgroundVideo(let url, let options):
            let opts = options ?? BackgroundVideoOptions()
            let loop = opts.loop ? "loop" : ""
            let muted = opts.muted ? "muted" : ""
            let autoplay = opts.autoplay ? "autoplay" : ""
            let controls = opts.controls ? "controls" : ""
            let poster = opts.poster != nil ? "poster='\(opts.poster!)'" : ""
            let videoType = opts.videoType
            
            // Create a unique identifier for the video element
            let videoId = "pageBackgroundVideo"
            
            // Build the video element HTML
            let videoHTML = """
                            <video id="\(videoId)" class="page-background-video" \(autoplay) \(loop) \(muted) \(controls) \(poster)>
                                <source src="\(url)" type="\(videoType)">
                            </video>
                            """
            
            script += """
                            var body = document.body;
                            body.style.margin = '0';
                            body.style.padding = '0';
                            body.insertAdjacentHTML('afterbegin', `\(videoHTML)`);
                            var videoElement = document.getElementById('\(videoId)');
                            videoElement.style.position = 'fixed';
                            videoElement.style.top = '0';
                            videoElement.style.left = '0';
                            videoElement.style.width = '100%';
                            videoElement.style.height = '100%';
                            videoElement.style.objectFit = 'cover';
                            videoElement.style.zIndex = '-1';
                            """
            
        case .fadeIn(let ref, let duration):
            if let ref = ref {
                script += """
                        var element = document.getElementById('\(ref)');
                        if (element) {
                            if (element.style.opacity === '' || parseFloat(element.style.opacity) < 1) {
                                element.style.opacity = 0;
                                element.style.display = 'block';
                                var last = +new Date();
                                var tick = function() {
                                    element.style.opacity = +element.style.opacity + (new Date() - last) / (\(duration) * 1000);
                                    last = +new Date();
                                    if (+element.style.opacity < 1) {
                                        (window.requestAnimationFrame && requestAnimationFrame(tick)) || setTimeout(tick, 16);
                                    }
                                };
                                tick();
                            }
                        }
                        """
            } else {
                script += """
                        if (\(builderId).style.opacity === '' || parseFloat(\(builderId).style.opacity) < 1) {
                            \(builderId).style.opacity = 0;
                            \(builderId).style.display = 'block';
                            var last = +new Date();
                            var tick = function() {
                                \(builderId).style.opacity = +\(builderId).style.opacity + (new Date() - last) / (\(duration) * 1000);
                                last = +new Date();
                                if (+\(builderId).style.opacity < 1) {
                                    (window.requestAnimationFrame && requestAnimationFrame(tick)) || setTimeout(tick, 16);
                                }
                            };
                            tick();
                        }
                        """
            }
            
        case .fadeOut(let ref, let duration):
            if let ref = ref {
                script += """
                        var element = document.getElementById('\(ref)');
                        if (element) {
                            element.style.opacity = 1;
                            var last = +new Date();
                            var tick = function() {
                                element.style.opacity = +element.style.opacity - (new Date() - last) / (\(duration) * 1000);
                                last = +new Date();
                                if (+element.style.opacity > 0) {
                                    (window.requestAnimationFrame && requestAnimationFrame(tick)) || setTimeout(tick, 16);
                                } else {
                                    element.style.display = 'none';
                                }
                            };
                            tick();
                        }
                        """
            } else {
                script += """
                        \(builderId).style.opacity = 1;
                        var last = +new Date();
                        var tick = function() {
                            \(builderId).style.opacity = +\(builderId).style.opacity - (new Date() - last) / (\(duration) * 1000);
                            last = +new Date();
                            if (+\(builderId).style.opacity > 0) {
                                (window.requestAnimationFrame && requestAnimationFrame(tick)) || setTimeout(tick, 16);
                            } else {
                                \(builderId).style.display = 'none';
                            }
                        };
                        tick();
                        """
            }
            
        case .fadeToggle(let ref, let duration):
            if let ref = ref {
                script += """
                        var element = document.getElementById('\(ref)');
                        if (element) {
                            if (element.style.display === 'none' || getComputedStyle(element).display === 'none') {
                                element.style.opacity = 0;
                                element.style.display = 'block';
                                var last = +new Date();
                                var tick = function() {
                                    element.style.opacity = +element.style.opacity + (new Date() - last) / (\(duration) * 1000);
                                    last = +new Date();
                                    if (+element.style.opacity < 1) {
                                        (window.requestAnimationFrame && requestAnimationFrame(tick)) || setTimeout(tick, 16);
                                    }
                                };
                                tick();
                            } else {
                                var last = +new Date();
                                var tick = function() {
                                    element.style.opacity = +element.style.opacity - (new Date() - last) / (\(duration) * 1000);
                                    last = +new Date();
                                    if (+element.style.opacity > 0) {
                                        (window.requestAnimationFrame && requestAnimationFrame(tick)) || setTimeout(tick, 16);
                                    } else {
                                        element.style.display = 'none';
                                    }
                                };
                                tick();
                            }
                        }
                        """
            } else {
                script += """
                        if (\(builderId).style.display === 'none' || getComputedStyle(\(builderId)).display === 'none') {
                            \(builderId).style.opacity = 0;
                            \(builderId).style.display = 'block';
                            var last = +new Date();
                            var tick = function() {
                                \(builderId).style.opacity = +\(builderId).style.opacity + (new Date() - last) / (\(duration) * 1000);
                                last = +new Date();
                                if (+\(builderId).style.opacity < 1) {
                                    (window.requestAnimationFrame && requestAnimationFrame(tick)) || setTimeout(tick, 16);
                                }
                            };
                            tick();
                        } else {
                            var last = +new Date();
                            var tick = function() {
                                \(builderId).style.opacity = +\(builderId).style.opacity - (new Date() - last) / (\(duration) * 1000);
                                last = +new Date();
                                if (+\(builderId).style.opacity > 0) {
                                    (window.requestAnimationFrame && requestAnimationFrame(tick)) || setTimeout(tick, 16);
                                } else {
                                    \(builderId).style.display = 'none';
                                }
                            };
                            tick();
                        }
                        """
            }
        case .addToArray(let variable, let value):
            script += """
                    // turn the variable from a JSON string into an temporary var array again
                    if (typeof \(variable.builderId) === 'string') {
                        var tempArray\(variable.builderId) = JSON.parse(\(variable.builderId));
                        if (Array.isArray(tempArray\(variable.builderId))) {
                            tempArray\(variable.builderId).push('\(value)');
                            updateWebVariable\(variable.builderId)(tempArray\(variable.builderId));
                        }
                    }
                    """
            
        case .removeFromArray(let variable, let value):
            script += """
                    // turn the variable from a JSON string into an temporary var array again
                    if (typeof \(variable.builderId) === 'string') {
                        var tempArray\(variable.builderId) = JSON.parse(\(variable.builderId));
                        if (Array.isArray(tempArray\(variable.builderId))) {
                            var index = tempArray\(variable.builderId).indexOf('\(value)');
                            if (index !== -1) {
                                tempArray\(variable.builderId).splice(index, 1);
                                updateWebVariable\(variable.builderId)(tempArray\(variable.builderId));
                            }
                        }
                    }
                    """
        case .toggleArray(let variable, let value):
            
            // if a value is there remove it, if it is not there add it
            script += """
                    // turn the variable from a JSON string into an temporary var array again
                    if (typeof \(variable.builderId) === 'string') {
                        var tempArray\(variable.builderId) = JSON.parse(\(variable.builderId));
                        if (Array.isArray(tempArray\(variable.builderId))) {
                            var index = tempArray\(variable.builderId).indexOf('\(value)');
                            if (index !== -1) {
                                tempArray\(variable.builderId).splice(index, 1);
                            } else {
                                tempArray\(variable.builderId).push('\(value)');
                            }
                            updateWebVariable\(variable.builderId)(tempArray\(variable.builderId));
                        }
                    }
                    """
            
        case .scrollTo(let ref, let behavior, let alignment):
            let refId = ref ?? builderId
            script += """
                    var element = document.getElementById('\(refId)');
                    element.scrollIntoView({ behavior: '\(behavior.rawValue)', block: '\(alignment.rawValue)', inline: '\(alignment.rawValue)' });
                    """
            
        case .showOffCanvas(let ref):
            script += """
            var offcanvasElement = document.getElementById('\(ref)');
            if (offcanvasElement) {
                var offcanvas = new bootstrap.Offcanvas(offcanvasElement);
                offcanvas.show();
            }
            """
            
        case .hideOffCanvas(let ref):
            script += """
            var offcanvasElement = document.getElementById('\(ref)');
            if (offcanvasElement) {
                var offcanvas = new bootstrap.Offcanvas(offcanvasElement);
                offcanvas.hide();
            }
            """
            
        case .carouselNext(let ref):
            script += """
            var carouselElement = document.getElementById('\(ref)');
            if (carouselElement) {
                var carousel = new bootstrap.Carousel(carouselElement);
                carousel.next();
            }
            """
            
        case .carouselPrev(let ref):
            script += """
            var carouselElement = document.getElementById('\(ref)');
            if (carouselElement) {
                var carousel = new bootstrap.Carousel(carouselElement);
                carousel.prev();
            }
            """
            
        case .carouselTo(let ref, let index):
            script += """
            var carouselElement = document.getElementById('\(ref)');
            if (carouselElement) {
                var carousel = new bootstrap.Carousel(carouselElement);
                carousel.to(\(index));
            }
            """
            
        case .accordionToggle(let ref):
            script += """
            var accordionElement = document.getElementById('\(ref)');
            if (accordionElement) {
                var accordion = new bootstrap.Collapse(accordionElement);
                accordion.toggle();
            }
            """
            
        case .progressSet(let ref, let value):
            script += """
            var progressElement = document.getElementById('\(ref)');
            if (progressElement) {
                var progressBar = progressElement.querySelector('.progress-bar');
                if (progressBar) {
                    progressBar.setAttribute('aria-valuenow', \(value));
                    progressBar.style.width = \(value) + '%';
                    var label = progressBar.querySelector('.progress-label');
                    if (label) {
                        label.textContent = \(value) + '%';
                    }
                }
            }
            """
            
        case .spinnerSet(let ref, let type, let size, let color, let label):
            script += """
            var spinnerElement = document.getElementById('\(ref)');
            if (spinnerElement) {
                spinnerElement.classList.remove('spinner-border', 'spinner-grow', 'spinner-border-sm', 'spinner-border-lg', 'spinner-grow-sm', 'spinner-grow-lg');
                spinnerElement.classList.add('\(type.rawValue)');
                if ('\(size.rawValue)' !== '') {
                    spinnerElement.classList.add('\(size.rawValue)');
                }
                spinnerElement.style.color = '\(color.rgba)';
                var labelElement = spinnerElement.querySelector('.sr-only');
                if (labelElement) {
                    labelElement.textContent = '\(label)';
                }
            }
            """
            
        case .handleResponse(_):
            // This case is handled within the .post case to inject the response data
            break
        case .navigate(let url):
            script += "window.location.href = '\(url)';\n"
        case .load(ref: let ref, url: let url):
            if let ref = ref {
                script += "document.getElementById('\(ref)').src = '\(url)';\n"
            } else {
                script += "\(builderId).src('\(url)');\n"
            }
        case .script(let scrpt):
            script += scrpt + "\n"
        case .post(
            url:             let url,
            values:          let values,
            onSuccessful:    let onSuccessful,
            onFailed:        let onFailed,
            onTimeout:       let onTimeout,
            resultInto:      let resultInto
        ):
            let id = "\(UUID().uuidString.lowercased().replacingOccurrences(of: "-", with:"").prefix(4))"
            
            // --- build the POST payload ---
            script += "var postData\(id) = {};\n"
            for value in values ?? [] {
                if let name = value.internalName {
                    script += "postData\(id)['\(name)'] = \(value.builderId);\n"
                }
            }
            
            // --- open and configure XHR ---
            script += "var xhr\(id) = new XMLHttpRequest();\n"
            script += "xhr\(id).open('POST', '\(url ?? "")', true);\n"
            script += "xhr\(id).setRequestHeader('Content-Type', 'application/json');\n"
            script += "xhr\(id).overrideMimeType('text/html');\n"
            // this flag makes the browser accept and store Set-Cookie headers
            script += "xhr\(id).withCredentials = true;\n\n"
            
            // --- state‑change handler (200‑range, failures, cookies & redirect) ---
            script += "xhr\(id).onreadystatechange = function() {\n"
            script += "  if (xhr\(id).readyState !== 4) return;\n"
            script += "  // 1) grab any cookies the server just set (HttpOnly ones won't appear here)\n"
            script += "  var cookies = document.cookie;\n\n"
            script += "  // 2) detect if the final URL is different (i.e. a redirect happened)\n"
            script += "  var finalURL = xhr\(id).responseURL;\n"
            script += "  if (finalURL && finalURL !== '\(url ?? "")') {\n"
            script += "    window.location.href = finalURL;\n"
            script += "    return;\n"
            script += "  }\n\n"
            script += "  // 3) success vs. failure based on status code\n"
            script += "  if (xhr\(id).status >= 200 && xhr\(id).status < 300) {\n"
            if let resultInto = resultInto {
                script += "    \(resultInto.builderId) = xhr\(id).responseText;\n"
            }
            if let onSuccessful = onSuccessful {
                for action in onSuccessful {
                    if case .handleResponse(let scriptContent) = action {
                        script += """
                                {
                                  var body    = xhr\(id).responseText;
                                  var status  = xhr\(id).status;
                                  var headers = xhr\(id).getAllResponseHeaders();
                                  var cookie  = cookies;
                                  \(scriptContent)
                                }
                                """
                    } else {
                        script += CompileActions([action], builderId: builderId)
                    }
                }
            }
            script += "  } else {\n"
            if let onFailed = onFailed {
                script += CompileActions(onFailed, builderId: builderId)
            }
            script += "  }\n"
            script += "};\n\n"
            
            // --- timeout handler (if any) ---
            if let onTimeout = onTimeout {
                // e.g. you could also do: xhr\(id).timeout = 10000; // 10s
                script += "xhr\(id).ontimeout = function() {\n"
                script += CompileActions(onTimeout, builderId: builderId)
                script += "};\n\n"
            }
            
            // --- send it off ---
            script += "xhr\(id).send(JSON.stringify(postData\(id)));\n"
            
        case .addClass(let className):
            script += "\(builderId).classList.add('\(className)');\n"
        case .removeClass(let className):
            script += "\(builderId).classList.remove('\(className)');\n"
        case .hidden(ref: let ref, let value):
            let action = value ? "add" : "remove"
            if let ref = ref {
                script += "document.getElementById('\(ref)').classList.\(action)('visually-hidden');\n"
            } else {
                script += "\(builderId).classList.\(action)('visually-hidden');\n"
            }
        case .if(let variable, let condition, let ifActions, let elseActions):
            let ifScript = CompileActions(ifActions, builderId: builderId)
            if let elseActions = elseActions {
                let elseScript = CompileActions(elseActions, builderId: builderId)
                script += "if (\(variable.builderId) \(condition.javascriptCondition)) {\n\(ifScript)\n} else {\n\(elseScript)\n}\n"
            } else {
                script += "if (\(variable.builderId) \(condition.javascriptCondition)) {\n\(ifScript)\n}\n"
            }
        case .toggle(let value):
            script += "updateWebVariable\(value.builderId)(!\(value.builderId));\n"
        case .foregroundColor(ref: let ref, let color):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.color = '\(color.rgba)';\n"
            } else {
                script += "\(builderId).style.color = '\(color.rgba)';\n"
            }
        case .backgroundColor(ref: let ref, let color):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.backgroundColor = '\(color.rgba)';\n"
            } else {
                script += "\(builderId).style.backgroundColor = '\(color.rgba)';\n"
            }
        case .underlineColor(ref: let ref, let color):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.textDecorationColor = '\(color.rgba)';\n"
            } else {
                script += "\(builderId).style.textDecorationColor = '\(color.rgba)';\n"
            }
        case .underline(ref: let ref, let value):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.textDecoration = \(value ? "'underline'" : "'none'");\n"
            } else {
                script += "\(builderId).style.textDecoration = \(value ? "'underline'" : "'none'");\n"
            }
        case .bold(ref: let ref, let value):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.fontWeight = \(value ? "'bold'" : "'normal'");\n"
            } else {
                script += "\(builderId).style.fontWeight = \(value ? "'bold'" : "'normal'");\n"
            }
        case .italic(ref: let ref, let value):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.fontStyle = \(value ? "'italic'" : "'normal'");\n"
            } else {
                script += "\(builderId).style.fontStyle = \(value ? "'italic'" : "'normal'");\n"
            }
        case .strikethrough(ref: let ref, let value):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.textDecoration = \(value ? "'line-through'" : "'none'");\n"
            } else {
                script += "\(builderId).style.textDecoration = \(value ? "'line-through'" : "'none'");\n"
            }
        case .fontSize(ref: let ref, let size):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.fontSize = '\(size)px';\n"
            } else {
                script += "\(builderId).style.fontSize = '\(size)px';\n"
            }
        case .fontFamily(ref: let ref, let name):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.fontFamily = '\(name)';\n"
            } else {
                script += "\(builderId).style.fontFamily = '\(name)';\n"
            }
        case .fontWeight(ref: let ref, let weight):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.fontWeight = '\(weight)';\n"
            } else {
                script += "\(builderId).style.fontWeight = '\(weight)';\n"
            }
        case .opacity(ref: let ref, let value):
            if let ref = ref {
                script += "document.getElementById('\(ref)').style.opacity = \(value);\n"
            } else {
                script += "\(builderId).style.opacity = \(value);\n"
            }
        case .random(let actions):
            let id = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
            script += "var randomIndex\(id) = Math.floor(Math.random() * \(actions.count));\n"
            script += "var functions\(id) = [];\n"
            for action in actions {
                script += "functions\(id).push(function() {\n"
                script += CompileActions([action], builderId: builderId)
                script += "});\n"
            }
            script += "functions\(id)[randomIndex\(id)]();\n"
        case .showModal(ref: let ref, contentURL: let contentURL):
            if let contentURL = contentURL {
                script += """
                fetch('\(contentURL)')
                    .then(response => response.text())
                    .then(data => {
                        document.getElementById('\(ref)').querySelector('.modal-body').innerHTML = data;
                        \(ref.md5.trimmingCharacters(in: CharacterSet.decimalDigits))ModalDialog.show();
                    });
                """
            } else {
                script += """
                if(\(ref.md5.trimmingCharacters(in: CharacterSet.decimalDigits))ModalDialog) {
                    \(ref.md5.trimmingCharacters(in: CharacterSet.decimalDigits))ModalDialog.show();
                }
                """
            }
        case .collapse(ref: let ref):
            script += """
            var myCollapse = new bootstrap.Collapse('#\(ref)', {
                hide: true
            });
            """
        case .hideModal(ref: let ref):
            script += """
            if(\(ref.md5.trimmingCharacters(in: CharacterSet.decimalDigits))ModalDialog) {
                \(ref.md5.trimmingCharacters(in: CharacterSet.decimalDigits))ModalDialog.hide();
            }
            """
        case .popover(title: let title, content: let content):
            script += """
            var popover = new bootstrap.Popover(\(builderId), {
                title: '\(title)',
                content: '\(content)'
            });
            popper.show();
            """
        case .src(ref: let ref, url: let url):
            if let ref = ref {
                script += "document.getElementById('\(ref)').src = '\(url)';\n"
            } else {
                script += "\(builderId).src = '\(url)';\n"
            }
        case .setVariable(let variable, to: let to):
            if let stringValue = to as? String {
                script += "updateWebVariable\(variable.builderId)('\(stringValue)');\n"
            } else if let intValue = to as? Int {
                script += "updateWebVariable\(variable.builderId)(\(intValue));\n"
            } else if let doubleValue = to as? Double {
                script += "updateWebVariable\(variable.builderId)(\(doubleValue));\n"
            } else if let boolValue = to as? Bool {
                script += "updateWebVariable\(variable.builderId)(\(boolValue ? "true" : "false"));\n"
            } else {
                script += "updateWebVariable\(variable.builderId)('\(to ?? "")');\n"
            }
        case .setInput(let inputName, to: let to):
            if let stringValue = to as? String {
                script += "document.getElementsByName('\(inputName)')[0].value = '\(stringValue)';\n"
            } else if let intValue = to as? Int {
                script += "document.getElementsByName('\(inputName)')[0].value = \(intValue);\n"
            } else if let doubleValue = to as? Double {
                script += "document.getElementsByName('\(inputName)')[0].value = \(doubleValue);\n"
            } else if let boolValue = to as? Bool {
                script += "document.getElementsByName('\(inputName)')[0].value = \(boolValue ? "true" : "false");\n"
            } else {
                script += "document.getElementsByName('\(inputName)')[0].value = '\(to ?? "")';\n"
            }
        case .setVariableName(let variableName, to: let to):
            if let stringValue = to as? String {
                script += "set\(variableName.md5)('\(stringValue)');\n"
            } else if let intValue = to as? Int {
                script += "set\(variableName.md5)(\(intValue));\n"
            } else if let doubleValue = to as? Double {
                script += "set\(variableName.md5)(\(doubleValue));\n"
            } else if let boolValue = to as? Bool {
                script += "set\(variableName.md5)(\(boolValue ? "true" : "false"));\n"
            } else {
                script += "set\(variableName.md5)('\(to ?? "")');\n"
            }
        }
    }
    
    return script
}


extension WebElement {
    
    internal func compileActions(_ actions: [WebAction]) -> String {
        return CompileActions(actions, builderId: builderId)
    }
    
}

public enum ScrollBehavior: String {
    case auto
    case smooth
}

public enum ScrollAlignment: String {
    case start
    case center
    case end
    case nearest
}
