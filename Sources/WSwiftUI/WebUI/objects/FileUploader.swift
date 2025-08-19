//
//  FileUploader.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 18/08/2025.
//

import Foundation

// 1) Dedicated subclass
public class WebFileUploaderElement: WebElement {}

// 2) Fluent config
public extension WebFileUploaderElement {
    /// Where to send the uploads
    @discardableResult
    func uploadURL(_ url: String) -> Self {
        addAttribute(.pair("data-upload-url", url))
        return self
    }
    
    /// HTTP method (defaults to POST)
    @discardableResult
    func method(_ method: String) -> Self {
        addAttribute(.pair("data-method", method))
        return self
    }
    
    /// Field name for the file(s) in multipart form
    @discardableResult
    func fieldName(_ name: String) -> Self {
        addAttribute(.pair("data-field-name", name))
        return self
    }
    
    /// Parallel uploads (concurrency)
    @discardableResult
    func parallelUploads(_ n: Int) -> Self {
        addAttribute(.pair("data-parallel", "\(max(1, n))"))
        return self
    }
    
    /// Attach extra fields (e.g. auth tokens) sent with each request
    @discardableResult
    func extraFields(_ fields: [String: String]) -> Self {
        if !fields.isEmpty,
           let json = try? String(data: JSONEncoder().encode(fields), encoding: .utf8) {
            // Escape quotes so it’s safe inside an HTML attribute
            let escaped = json.replacingOccurrences(of: "\"", with: "&quot;")
            addAttribute(.pair("data-extra", escaped))
        }
        return self
    }
}

// 3) DSL on CoreWebEndpoint
public extension CoreWebEndpoint {
    
    /// Internal helper for creating uploader elements
    fileprivate func createUploader(_ `init`: (_ element: WebFileUploaderElement) -> Void) -> WebFileUploaderElement {
        let element = WebFileUploaderElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }
    
    /// File drop uploader with overall progress bar
    ///
    /// - Parameters:
    ///   - action: URL to POST/PUT files to
    ///   - method: HTTP method (default "POST")
    ///   - fieldName: multipart key (default "files[]")
    ///   - parallelUploads: number of concurrent uploads (default 3)
    ///   - extraFields: extra multipart fields to include (e.g. ["token": "..."])
    @discardableResult
    func FileUploader(
        action url: String,
        method: String = "POST",
        fieldName: String = "files[]",
        parallelUploads: Int = 3,
        extraFields: [String: String] = [:],
        _ content: WebComposerClosure
    ) -> WebFileUploaderElement {
        
        let uploader = createUploader { el in
            el.elementName = "div"
            // Keep the outer element plain; add light utility classes you can drop if you prefer
            el.class("border")
            el.class("rounded")
            el.class("p-3")
            el.class("file-uploader")
            
            // Config via data-* for the JS to read
            el.uploadURL(url)
                .method(method)
                .fieldName(fieldName)
                .parallelUploads(parallelUploads)
                .extraFields(extraFields)
        }
        
        // Put uploader on the stack so user content nests inside it
        stack.append(uploader)
        content()
        
        // Append a Bootstrap progress bar at the bottom
        _ = createUploader { el in
            el.elementName = "div"
            el.class("progress")
            el.class("mt-2")
            el.addAttribute(.pair("id", "progress_\(uploader.builderId)"))
            
            _ = createUploader { bar in
                bar.elementName = "div"
                bar.class("progress-bar")
                bar.addAttribute(.pair("role", "progressbar"))
                bar.addAttribute(.pair("style", "width:0%"))
                bar.addAttribute(.pair("aria-valuemin", "0"))
                bar.addAttribute(.pair("aria-valuemax", "100"))
                bar.addAttribute(.pair("aria-valuenow", "0"))
                bar.addAttribute(.pair("id", "progressbar_\(uploader.builderId)"))
            }
        }
        
        // Wire up drag&drop + uploads via XHR (for upload progress events)
        uploader.script("""
        (function() {
            var zone = document.getElementById('\(uploader.builderId)');
            if (!zone) return;
        
            var progressBar = document.getElementById('progressbar_\(uploader.builderId)');
            function setProgress(p) {
                if (!progressBar) return;
                var pct = Math.max(0, Math.min(100, Math.floor(p)));
                progressBar.style.width = pct + '%';
                progressBar.setAttribute('aria-valuenow', pct);
                progressBar.textContent = pct + '%';
            }
        
            var uploadURL   = zone.getAttribute('data-upload-url') || '';
            var method      = zone.getAttribute('data-method') || 'POST';
            var fieldName   = zone.getAttribute('data-field-name') || 'files[]';
            var parallelStr = zone.getAttribute('data-parallel') || '3';
            var parallel    = Math.max(1, parseInt(parallelStr, 10) || 3);
        
            var extra = {};
            try {
                var extraAttr = zone.getAttribute('data-extra');
                if (extraAttr) extra = JSON.parse(extraAttr);
            } catch (e) { /* ignore */ }
        
            function preventDefaults(e) { e.preventDefault(); e.stopPropagation(); }
            ['dragenter','dragover','dragleave','drop'].forEach(function(ev) {
                zone.addEventListener(ev, preventDefaults, false);
            });
        
            zone.addEventListener('dragover', function() { zone.classList.add('bg-light'); }, false);
            zone.addEventListener('dragleave', function() { zone.classList.remove('bg-light'); }, false);
            zone.addEventListener('drop', function(e) {
                zone.classList.remove('bg-light');
                var files = (e.dataTransfer && e.dataTransfer.files) ? Array.from(e.dataTransfer.files) : [];
                if (files.length) uploadFiles(files);
            }, false);
        
            function uploadFiles(files) {
                var totalBytes = files.reduce(function(sum, f) { return sum + (f.size || 0); }, 0);
                var uploadedBytes = 0;
                var inFlight = 0;
                var index = 0;
        
                function next() {
                    while (inFlight < parallel && index < files.length) {
                        send(files[index++]);
                    }
                    if (inFlight === 0 && index >= files.length) {
                        // small delay so users see 100% before reset
                        setTimeout(function() { setProgress(0); }, 800);
                    }
                }
        
                function send(file) {
                    inFlight++;
                    var form = new FormData();
                    form.append(fieldName, file, file.name);
                    Object.keys(extra).forEach(function(k){ form.append(k, extra[k]); });
        
                    var xhr = new XMLHttpRequest();
                    var lastLoaded = 0;
        
                    xhr.open(method, uploadURL, true);
        
                    // Overall progress across all files
                    xhr.upload.onprogress = function(e) {
                        if (e.lengthComputable) {
                            var delta = e.loaded - lastLoaded;
                            lastLoaded = e.loaded;
                            uploadedBytes += Math.max(0, delta);
                            var pct = totalBytes > 0 ? (uploadedBytes / totalBytes) * 100 : 100;
                            setProgress(pct);
                        }
                    };
        
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === 4) {
                            inFlight--;
                            // NOTE: handle xhr.status here if you want success/failure hooks
                            next();
                        }
                    };
        
                    xhr.send(form);
                }
        
                setProgress(1);
                next();
            }
        })();
        """)
        
        // Pop uploader from stack
        stack.removeAll(where: { $0.builderId == uploader.builderId })
        return uploader
    }
}
