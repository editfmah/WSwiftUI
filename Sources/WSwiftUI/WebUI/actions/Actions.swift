//
//  Actions.swift
//
//
//  Created by Adrian Herridge on 21/05/2024.
//

import Foundation

extension String {
    /// MD5 of the UTF-8 bytes, hex-encoded (lowercase)
    var md5: String {
        // 1) Prepare message
        let message = Array(self.utf8)
        let bitLen = UInt64(message.count) * 8
        
        // append 0x80, then pad with 0x00 until length ≡ 448 (mod 512)
        var padded = message + [0x80]
        while ((padded.count * 8) % 512) != 448 {
            padded.append(0)
        }
        // append original length (bits) as 64-bit little-endian
        padded += bitLen.bytesLE
        
        // 2) Initialize state
        var a0: UInt32 = 0x67452301
        var b0: UInt32 = 0xefcdab89
        var c0: UInt32 = 0x98badcfe
        var d0: UInt32 = 0x10325476
        
        // 3) Constants
        let K: [UInt32] = (0..<64).map { i in
            // floor(abs(sin(i+1)) * 2^32)
            let x = floor(abs(sin(Double(i + 1))) * 4294967296.0)
            return UInt32(truncatingIfNeeded: UInt64(x))
        }
        let s: [UInt32] = [
            7,12,17,22, 7,12,17,22, 7,12,17,22, 7,12,17,22,
            5, 9,14,20, 5, 9,14,20, 5, 9,14,20, 5, 9,14,20,
            4,11,16,23, 4,11,16,23, 4,11,16,23, 4,11,16,23,
            6,10,15,21, 6,10,15,21, 6,10,15,21, 6,10,15,21
        ]
        
        // 4) Process 512-bit chunks
        for chunkStart in stride(from: 0, to: padded.count, by: 64) {
            let chunk = Array(padded[chunkStart..<chunkStart+64])
            // break into 16 little-endian 32-bit words
            var M = [UInt32](repeating: 0, count: 16)
            for j in 0..<16 {
                let i = j * 4
                M[j] =  UInt32(chunk[i])
                | (UInt32(chunk[i+1]) << 8)
                | (UInt32(chunk[i+2]) << 16)
                | (UInt32(chunk[i+3]) << 24)
            }
            
            var A = a0, B = b0, C = c0, D = d0
            for i in 0..<64 {
                let (F, g): (UInt32, Int) = {
                    switch i {
                        case 0..<16:   return ( (B & C) | ((~B) & D),           i )
                        case 16..<32:  return ( (D & B) | ((~D) & C),  (5*i+1) % 16 )
                        case 32..<48:  return ( B ^ C ^ D,            (3*i+5) % 16 )
                        default:       return ( C ^ (B | (~D)),        (7*i)   % 16 )
                    }
                }()
                let tmp = D
                D = C
                C = B
                B = B &+ rotl(A &+ F &+ K[i] &+ M[g], s[i])
                A = tmp
            }
            
            a0 = a0 &+ A
            b0 = b0 &+ B
            c0 = c0 &+ C
            d0 = d0 &+ D
        }
        
        // 5) Output little-endian digest as hex
        let digestWords = [a0, b0, c0, d0]
        var out = [UInt8]()
        out.reserveCapacity(16)
        for w in digestWords {
            let le = w.littleEndian
            out.append(UInt8(truncatingIfNeeded: le >> 0))
            out.append(UInt8(truncatingIfNeeded: le >> 8))
            out.append(UInt8(truncatingIfNeeded: le >> 16))
            out.append(UInt8(truncatingIfNeeded: le >> 24))
        }
        return out.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - helpers

@inline(__always)
private func rotl(_ x: UInt32, _ n: UInt32) -> UInt32 {
    return (x << n) | (x >> (32 - n))
}

private extension UInt64 {
    /// 8 bytes, little-endian
    var bytesLE: [UInt8] {
        var v = self.littleEndian
        return withUnsafeBytes(of: &v) { Array($0) }
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
    
    // result handling activities
    case extractJSON(key: String, actions: [WebAction])
    case extractJSONInto(key: String, into: WebVariableElement)
    case evaluate(op: Operator,_ true: [WebAction],_ else: [WebAction]?)
    
    case text(ref: String? = nil, _ value: String)
    case html(ref: String? = nil, _ value: String)
    case appendHTML(ref: String? = nil, _ html: String)
    case prependHTML(ref: String? = nil, _ html: String)
    case setAttribute(ref: String? = nil, name: String, value: String?)
    case removeAttribute(ref: String? = nil, name: String)
    case toggleClass(ref: String? = nil, className: String)

    case show(ref: String? = nil)
    case hide(ref: String? = nil)
    case enable(ref: String? = nil)
    case disable(ref: String? = nil)
    case focus(ref: String? = nil)
    case blur(ref: String? = nil)
    case click(ref: String? = nil)

    case setCSSVariable(ref: String? = nil, name: String, value: String)
    case setStyles(ref: String? = nil, styles: [String: String])

    case animate(ref: String? = nil, keyframes: String, options: String)
    case addClassFor(ref: String? = nil, className: String, durationMs: Int)

    case localStorageSet(key: String, value: WebVariableElement)
    case localStorageGet(key: String, into: WebVariableElement)
    case localStorageRemove(key: String)

    case sessionStorageSet(key: String, value: WebVariableElement)
    case sessionStorageGet(key: String, into: WebVariableElement)
    case sessionStorageRemove(key: String)

    case clipboardCopy(_ value: WebVariableElement)

    case get(url: String, onSuccessful: [WebAction]? = nil, onFailed: [WebAction]? = nil, onTimeout: [WebAction]? = nil, resultInto: WebVariableElement? = nil)
    case download(url: String, filename: String?)

    case reload
    case historyBack
    case historyForward
    case historyPush(url: String, title: String?)
    case historyReplace(url: String, title: String?)
    case openNewWindow(url: String, target: String)

    case tooltipShow(ref: String)
    case tooltipHide(ref: String)
    case toastShow(ref: String)
    case toastHide(ref: String)
    case tabShow(ref: String)

    case delay(seconds: Double, actions: [WebAction])
    case alert(_ message: String)
    case confirm(_ message: String, ifYes: [WebAction], ifNo: [WebAction]?)

    case setVariableFromExpression(into: WebVariableElement, expression: String)
    case regexExtract(source: WebVariableElement, pattern: String, group: Int, into: WebVariableElement)

    case setAria(ref: String? = nil, name: String, value: String)
    case ariaAnnounce(message: String, politeness: String)
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
                if ('\(size.rawValue)' != '') {
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
            popover.show();
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
        case .extractJSON(key: let key, actions: let actions):
            // Parse JSON from `result` only (string or object) and expose a new scoped `result` for subsequent actions.
            let nested = CompileActions(actions, builderId: builderId)
            script += #"""
            (function(){
                var __source = (typeof result !== 'undefined') ? result : null;
                var __obj = null;
                try {
                    if (__source === null || typeof __source === 'undefined') {
                        __obj = null;
                    } else if (typeof __source === 'string') {
                        __obj = JSON.parse(__source);
                    } else {
                        // already an object/array
                        __obj = __source;
                    }
                } catch(e) {
                    __obj = null;
                }

                // Resolve key path supporting dot and bracket notation (e.g., a.b[0].c)
                var __extracted = __obj;
                var __path = "\#(key)";
                if (__path && typeof __path === 'string' && __path.length > 0) {
                    var __parts = __path.replace(/\[(\d+)\]/g, '.$1').split('.').filter(function(p){ return p.length > 0; });
                    for (var __i = 0; __i < __parts.length; __i++) {
                        var __p = __parts[__i];
                        if (__extracted != null && Object.prototype.hasOwnProperty.call(__extracted, __p)) {
                            __extracted = __extracted[__p];
                        } else if (__extracted != null && typeof __extracted === 'object' && __p in __extracted) {
                            // fallback for prototype-less checks
                            __extracted = __extracted[__p];
                        } else {
                            __extracted = undefined;
                            break;
                        }
                    }
                }

                // Shadow `result` within this scope for subsequent compiled actions
                var result = __extracted;

                // Execute nested actions in the context of this new `result`
                (function(){
                    \#(nested)
                })();
            })();
            """#
        case .extractJSONInto(key: let key, into: let variable):
            // Extract a value from JSON in `result` and write it into the specified variable.
            script += #"""
            (function(){
                var __source = (typeof result !== 'undefined') ? result : null;
                var __obj = null;
                try {
                    if (__source === null || typeof __source === 'undefined') {
                        __obj = null;
                    } else if (typeof __source === 'string') {
                        __obj = JSON.parse(__source);
                    } else {
                        // already an object/array
                        __obj = __source;
                    }
                } catch(e) {
                    __obj = null;
                }

                // Resolve key path supporting dot and bracket notation (e.g., a.b[0].c)
                var __extracted = __obj;
                var __path = "\#(key)";
                if (__path && typeof __path === 'string' && __path.length > 0) {
                    var __parts = __path.replace(/\[(\d+)\]/g, '.$1').split('.').filter(function(p){ return p.length > 0; });
                    for (var __i = 0; __i < __parts.length; __i++) {
                        var __p = __parts[__i];
                        if (__extracted != null && Object.prototype.hasOwnProperty.call(__extracted, __p)) {
                            __extracted = __extracted[__p];
                        } else if (__extracted != null && typeof __extracted === 'object' && __p in __extracted) {
                            // fallback for prototype-less checks
                            __extracted = __extracted[__p];
                        } else {
                            __extracted = undefined;
                            break;
                        }
                    }
                }

                // Update the specified web variable with the extracted value
                updateWebVariable\#(variable.builderId)(__extracted);
            })();
            """#
        case .evaluate(op: let op, let ifTrue, let ifFalse):
            let ifScript = CompileActions(ifTrue, builderId: builderId)
            let elseScript = ifFalse.map { CompileActions($0, builderId: builderId) }
            script += """
            (function(){
                var __cond = false;
                try {
                    __cond = (result \(op.javascriptCondition));
                } catch (e) {
                    __cond = false;
                }
                if (__cond) {
            """ + ifScript + """
                } else {
            """ + (elseScript ?? "") + """
                }
            })();
            """

        case .text(let ref, let value):
            if let ref = ref {
                script += "document.getElementById('\(ref)').textContent = `\(value)`;\n"
            } else {
                script += "\(builderId).textContent = `\(value)`;\n"
            }
        case .html(let ref, let value):
            if let ref = ref {
                script += "document.getElementById('\(ref)').innerHTML = `\(value)`;\n"
            } else {
                script += "\(builderId).innerHTML = `\(value)`;\n"
            }
        case .appendHTML(let ref, let html):
            let target = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(target).insertAdjacentHTML('beforeend', `\(html)`);\n"
        case .prependHTML(let ref, let html):
            let target2 = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(target2).insertAdjacentHTML('afterbegin', `\(html)`);\n"
        case .setAttribute(let ref, let name, let value):
            let tgt = ref.map { "document.getElementById('\($0)')" } ?? builderId
            if let value = value {
                script += "\(tgt).setAttribute('\(name)', '\(value)');\n"
            } else {
                script += "\(tgt).setAttribute('\(name)', '');\n"
            }
        case .removeAttribute(let ref, let name):
            let tgt2 = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(tgt2).removeAttribute('\(name)');\n"
        case .toggleClass(let ref, let className):
            let tgt3 = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(tgt3).classList.toggle('\(className)');\n"

        case .show(let ref):
            let tShow = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(tShow).style.display = '';\n"
        case .hide(let ref):
            let tHide = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(tHide).style.display = 'none';\n"
        case .enable(let ref):
            let tEnable = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(tEnable).removeAttribute('disabled');\n"
        case .disable(let ref):
            let tDisable = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(tDisable).setAttribute('disabled','disabled');\n"
        case .focus(let ref):
            let tFocus = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "(function(el){ if(el&&el.focus) el.focus(); })(\(tFocus));\n"
        case .blur(let ref):
            let tBlur = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "(function(el){ if(el&&el.blur) el.blur(); })(\(tBlur));\n"
        case .click(let ref):
            let tClick = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "(function(el){ if(el&&el.click) el.click(); })(\(tClick));\n"

        case .setCSSVariable(let ref, let name, let value):
            let tCSS = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(tCSS).style.setProperty('\(name)', '\(value)');\n"
        case .setStyles(let ref, let styles):
            let tStyles = ref.map { "document.getElementById('\($0)')" } ?? builderId
            let objLiteral = "{" + styles.map { "'\($0.key)': '\($0.value)'" }.joined(separator: ", ") + "}"
            script += "(function(el, styles){ if(!el) return; for (var k in styles){ if (Object.prototype.hasOwnProperty.call(styles,k)) { el.style[k] = styles[k]; } } })(\(tStyles), \(objLiteral));\n"

        case .animate(let ref, let keyframes, let options):
            let tAnim = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "(function(el){ if(!el||!el.animate) return; el.animate(\(keyframes), \(options)); })(\(tAnim));\n"
        case .addClassFor(let ref, let className, let durationMs):
            let tACF = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "(function(el){ if(!el) return; el.classList.add('\(className)'); setTimeout(function(){ el.classList.remove('\(className)'); }, \(durationMs)); })(\(tACF));\n"

        case .localStorageSet(let key, let value):
            script += "localStorage.setItem('\(key)', JSON.stringify(\(value.builderId)));\n"
        case .localStorageGet(let key, let into):
            script += "(function(){ var v = localStorage.getItem('\\(key)'); try { v = JSON.parse(v); } catch(e){} updateWebVariable\(into.builderId)(v); })();\n"
        case .localStorageRemove(let key):
            script += "localStorage.removeItem('\(key)');\n"

        case .sessionStorageSet(let key, let value):
            script += "sessionStorage.setItem('\(key)', JSON.stringify(\(value.builderId)));\n"
        case .sessionStorageGet(let key, let into):
            script += "(function(){ var v = sessionStorage.getItem('\\(key)'); try { v = JSON.parse(v); } catch(e){} updateWebVariable\(into.builderId)(v); })();\n"
        case .sessionStorageRemove(let key):
            script += "sessionStorage.removeItem('\(key)');\n"

        case .clipboardCopy(let value):
            script += "(function(txt){ if (navigator.clipboard && navigator.clipboard.writeText) { navigator.clipboard.writeText(String(txt)); } else { var ta = document.createElement('textarea'); ta.value = String(txt); document.body.appendChild(ta); ta.select(); try { document.execCommand('copy'); } catch(e){} document.body.removeChild(ta); } })(\(value.builderId));\n"

        case .get(let url, let onSuccessful, let onFailed, let onTimeout, let resultInto):
            let gid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(4)
            script += "var xhr\(gid) = new XMLHttpRequest();\n"
            script += "xhr\(gid).open('GET', '\(url)', true);\n"
            script += "xhr\(gid).withCredentials = true;\n"
            script += "xhr\(gid).onreadystatechange = function(){\n"
            script += "  if (xhr\(gid).readyState !== 4) return;\n"
            script += "  if (xhr\(gid).status >= 200 && xhr\(gid).status < 300) {\n"
            if let resultInto = resultInto {
                script += "    \(resultInto.builderId) = xhr\(gid).responseText;\n"
            }
            if let onSuccessful = onSuccessful {
                for a in onSuccessful {
                    script += CompileActions([a], builderId: builderId)
                }
            }
            script += "  } else {\n"
            if let onFailed = onFailed {
                script += CompileActions(onFailed, builderId: builderId)
            }
            script += "  }\n";
            script += "};\n"
            if let onTimeout = onTimeout {
                script += "xhr\(gid).ontimeout = function(){\n"
                script += CompileActions(onTimeout, builderId: builderId)
                script += "};\n"
            }
            script += "xhr\(gid).send();\n"

        case .download(let url, let filename):
            script += "(function(u,f){ var a = document.createElement('a'); a.href = u; if (f) a.download = f; document.body.appendChild(a); a.click(); document.body.removeChild(a); })(\"\(url)\", \(filename != nil ? "'\(filename!)'" : "null"));\n"

        case .reload:
            script += "window.location.reload();\n"
        case .historyBack:
            script += "window.history.back();\n"
        case .historyForward:
            script += "window.history.forward();\n"
        case .historyPush(let url, let title):
            script += "window.history.pushState({}, '\(title ?? "")', '\(url)');\n"
        case .historyReplace(let url, let title):
            script += "window.history.replaceState({}, '\(title ?? "")', '\(url)');\n"
        case .openNewWindow(let url, let target):
            script += "window.open('\(url)', '\(target)');\n"

        case .tooltipShow(let ref):
            script += "(function(){ var el = document.getElementById('\\(ref)'); if(!el) return; var tt = bootstrap.Tooltip.getOrCreateInstance(el); tt.show(); })();\n"
        case .tooltipHide(let ref):
            script += "(function(){ var el = document.getElementById('\\(ref)'); if(!el) return; var tt = bootstrap.Tooltip.getOrCreateInstance(el); tt.hide(); })();\n"
        case .toastShow(let ref):
            script += "(function(){ var el = document.getElementById('\\(ref)'); if(!el) return; var toast = bootstrap.Toast.getOrCreateInstance(el); toast.show(); })();\n"
        case .toastHide(let ref):
            script += "(function(){ var el = document.getElementById('\\(ref)'); if(!el) return; var toast = bootstrap.Toast.getOrCreateInstance(el); toast.hide(); })();\n"
        case .tabShow(let ref):
            script += "(function(){ var el = document.getElementById('\\(ref)'); if(!el) return; var tab = new bootstrap.Tab(el); tab.show(); })();\n"

        case .delay(let seconds, let actions):
            let nested = CompileActions(actions, builderId: builderId)
            script += "setTimeout(function(){\n\(nested)\n}, \(Int(seconds * 1000)));\n"
        case .alert(let message):
            script += "window.alert('\(message)');\n"
        case .confirm(let message, let ifYes, let ifNo):
            let yesScript = CompileActions(ifYes, builderId: builderId)
            let noScript = ifNo.map { CompileActions($0, builderId: builderId) } ?? ""
            script += "if (window.confirm('\(message)')) {\n\(yesScript)\n} else {\n\(noScript)\n}\n"

        case .setVariableFromExpression(let into, let expression):
            script += "updateWebVariable\(into.builderId)((function(){ try { return (\(expression)); } catch(e){ return null; } })());\n"
        case .regexExtract(let source, let pattern, let group, let into):
            script += "(function(s, re, g){ try { var r = new RegExp(re).exec(String(s)); var v = (r && r.length > g) ? r[g] : null; updateWebVariable\(into.builderId)(v); } catch(e){ updateWebVariable\(into.builderId)(null); } })(\(source.builderId), '\(pattern.replacingOccurrences(of: "\\", with: "\\\\"))', \(group));\n"

        case .setAria(let ref, let name, let value):
            let tAria = ref.map { "document.getElementById('\($0)')" } ?? builderId
            script += "\(tAria).setAttribute('\(name)', '\(value)');\n"
        case .ariaAnnounce(let message, let politeness):
            script += "(function(msg, politeness){ var lr = document.getElementById('__live_region__'); if(!lr){ lr = document.createElement('div'); lr.id='__live_region__'; lr.setAttribute('aria-live', politeness||'polite'); lr.setAttribute('aria-atomic','true'); lr.style.position='absolute'; lr.style.width='1px'; lr.style.height='1px'; lr.style.overflow='hidden'; lr.style.clip='rect(1px, 1px, 1px, 1px)'; lr.style.clipPath='inset(50%)'; lr.style.whiteSpace='nowrap'; lr.style.border='0'; document.body.appendChild(lr);} lr.textContent = msg; })('\(message)', '\(politeness)');\n"
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




