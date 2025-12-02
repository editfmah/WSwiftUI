//
//  WebData.swift
//  WSwiftUI
//
//  Created by Adrian on 27/07/2025.
//

import Foundation

public class WebData {
    
    private var jsonBody: Data? = nil
    private var combined: [String: String] = [:]
    private var wVarTransaction: WebVariableTransaction?
    
    public struct FilePart {
        public let fieldName: String
        public let filename: String?
        public let contentType: String?
        public let data: Data?          // nil for streamed-on-disk uploads
        public let tempUrl: URL?        // non-nil for streamed file parts
    }
    private(set) var files: [String: FilePart] = [:]
    
    public func consume(_ data: [String: String]) {
        for (k, v) in data {
            combined[k] = v
        }
    }
    
    public func consume(_ body: [UInt8]) {
        let data = Data(body)
        consume(data)
    }
    
    public func consume(_ body: Data) {
        let contentType = combined["content-type"] ?? ""
        
        if contentType.contains("application/json") {
            consumeJSON(body)
        } else if contentType.contains("application/x-www-form-urlencoded") {
            consumeURLEncoded(body)
        } else if contentType.contains("multipart/form-data"),
                  let boundary = boundary(from: contentType) {
            // In-memory multipart path (unchanged)
            consumeMultipart(body, boundary: boundary)
        } else {
            if let text = String(data: body, encoding: .utf8) {
                combined["body"] = text
            }
        }
    }
    
    // allow the consumption of a file url where body data was written
    public func consume(_ body: HttpBody) {
        switch body {
            case .none:
                break
                
            case .inMemory(let mem):
                consume(mem)
                
            case .onDisk(url: let url, size: _):
                let contentType = combined["content-type"] ?? ""
                if contentType.contains("multipart/form-data"),
                   let boundary = boundary(from: contentType) {
                    do {
                        try consumeMultipart(fromFile: url, boundary: boundary)
                    } catch {
                        // Fallback: if streaming parse fails for any reason, fall back to in-memory
                        if let data = try? Data(contentsOf: url) {
                            consume(data)
                        }
                    }
                } else {
                    // Not multipart: keep original behavior
                    if let data = try? Data(contentsOf: url) {
                        consume(data)
                    }
                }
        }
    }
    
    // MARK: - Streaming multipart from file (no large in-memory buffers)
    private func consumeMultipart(fromFile url: URL, boundary: String) throws {
        // Tokens as Data (avoid '+' operator & availability issues)
        let dd = Data("--".utf8)                // --
        let crlf = Data("\r\n".utf8)            // \r\n
        let b = Data(boundary.utf8)             // boundary
        var boundaryLine = dd                   // --boundary
        boundaryLine.append(b)
        
        // Delimiters
        var delimiter = crlf                    // \r\n--boundary
        delimiter.append(boundaryLine)
        
        var delimiterFinal = delimiter          // \r\n--boundary--
        delimiterFinal.append(dd)
        
        let headerSep = Data("\r\n\r\n".utf8)   // header terminator
        
        let fh = try FileHandle(forReadingFrom: url)
        defer { fh.closeFile() }
        
        // Rolling buffer; we flush to disk as soon as it's safe.
        let chunkSize = 64 * 1024
        var buffer = Data()
        var eof = false
        
        @inline(__always)
        func fill() {
            if eof { return }
            let d = fh.readData(ofLength: chunkSize)
            if d.isEmpty {
                eof = true
            } else {
                buffer.append(d)
            }
        }
        
        // Read enough to find the *opening* boundary: `--boundary` (optionally after a preamble)
        while !eof && buffer.range(of: boundaryLine) == nil { fill() }
        guard let first = buffer.range(of: boundaryLine) else { return } // nothing to parse
        
        // Position after opening boundary and optional CRLF
        var cursor = first.upperBound
        if buffer.count < cursor + 2 { fill() }
        if buffer.count >= cursor + 2, buffer[cursor..<cursor+2] == crlf {
            cursor += 2
        }
        buffer.removeSubrange(0..<cursor)
        
        // Utility: write safely to a FileHandle and swallow errors (best-effort)
        @inline(__always)
        func safeWrite(_ out: FileHandle?, _ data: Data) {
            guard let out = out, !data.isEmpty else { return }
            out.write(data) // non-throwing, widely available
        }
        
        // After each part, the format is:
        // [headers]\r\n\r\n[body]\r\n--boundary[--]\r\n?
        partsLoop: while true {
            // Ensure headers are fully present
            while !eof && buffer.range(of: headerSep) == nil { fill() }
            guard let headerEnd = buffer.range(of: headerSep) else { break } // no more parts
            
            // Parse headers
            let headerData = buffer.subdata(in: 0..<headerEnd.lowerBound)
            var fieldName: String?
            var fileName: String?
            var contentType: String?
            
            if let headerText = String(data: headerData, encoding: .utf8) {
                for line in headerText.split(separator: "\r\n") {
                    let header = String(line)
                    if header.lowercased().hasPrefix("content-disposition:") {
                        let parts = header.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
                        for p in parts {
                            if p.hasPrefix("name=") {
                                fieldName = p.split(separator: "=", maxSplits: 1)[1]
                                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                            } else if p.hasPrefix("filename=") {
                                fileName = p.split(separator: "=", maxSplits: 1)[1]
                                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                            }
                        }
                    } else if header.lowercased().hasPrefix("content-type:") {
                        contentType = header.split(separator: ":", maxSplits: 1)[1]
                            .trimmingCharacters(in: .whitespaces)
                    }
                }
            }
            
            // Advance to body start
            let bodyStart = headerEnd.upperBound
            buffer.removeSubrange(0..<bodyStart)
            
            // If it's a file part, stream to a temp file
            let isFile = (fileName != nil)
            var outHandle: FileHandle?
            var tempURL: URL?
            if isFile {
                let originalName = fileName ?? "upload.bin"
                let ext = (originalName as NSString).pathExtension
                var tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                if !ext.isEmpty { tmp.appendPathExtension(ext) }
                // Ensure file exists
                FileManager.default.createFile(atPath: tmp.path, contents: nil, attributes: nil)
                tempURL = tmp
                outHandle = try? FileHandle(forWritingTo: tmp)
            }
            
            // We'll search for delimiter incrementally. Keep a small tail in memory to detect split boundaries.
            // We can safely flush everything except the last `reserve` bytes.
            let reserve = max(delimiter.count + 4, 64) // 64 is just a comfortable minimum
            
            func findDelimiter() -> (range: Range<Data.Index>, isFinal: Bool)? {
                if let r = buffer.range(of: delimiter) {
                    var final = false
                    let after = r.upperBound
                    if buffer.count >= after + 2 && buffer[after..<after+2] == dd { final = true }
                    return (r, final)
                }
                return nil
            }
            
            if isFile {
                // STREAMING WRITE
                while true {
                    if let hit = findDelimiter() {
                        // Write everything up to CRLF before the delimiter
                        let start = buffer.startIndex
                        let end = hit.range.lowerBound
                        let payloadEnd = end >= 2 ? end - 2 : end
                        if payloadEnd > start {
                            safeWrite(outHandle, buffer[start..<payloadEnd])
                        }
                        // Consume through delimiter and optional "--"
                        var consumeTo = hit.range.upperBound
                        if hit.isFinal {
                            if buffer.count < consumeTo + 2 { fill() }
                            consumeTo = min(buffer.count, consumeTo + 2) // skip trailing "--"
                        }
                        if consumeTo > buffer.count { consumeTo = buffer.count }
                        buffer.removeSubrange(0..<consumeTo)
                        // If not final, optional CRLF follows; consume it so next read starts at next part's headers
                        if !hit.isFinal {
                            if buffer.count < 2 { fill() }
                            if buffer.count >= 2, buffer.prefix(2) == crlf {
                                buffer.removeFirst(2)
                            }
                        }
                        outHandle?.closeFile()
                        outHandle = nil
                        
                        if let name = fieldName, let fn = fileName {
                            files[name] = FilePart(fieldName: name,
                                                   filename: fn,
                                                   contentType: contentType,
                                                   data: nil,
                                                   tempUrl: tempURL)
                        }
                        if hit.isFinal { break partsLoop }
                        break // proceed to next part
                    }
                    
                    // No delimiter yet; flush safe prefix and read more
                    if buffer.count > reserve {
                        let flushCount = buffer.count - reserve
                        safeWrite(outHandle, buffer.prefix(flushCount))
                        buffer.removeFirst(flushCount)
                    } else {
                        if eof { // Malformed, no delimiter found before EOF: write what's left and bail
                            safeWrite(outHandle, buffer)
                            buffer.removeAll(keepingCapacity: false)
                            outHandle?.closeFile()
                            if let name = fieldName, let fn = fileName {
                                files[name] = FilePart(fieldName: name,
                                                       filename: fn,
                                                       contentType: contentType,
                                                       data: nil,
                                                       tempUrl: tempURL)
                            }
                            break partsLoop
                        }
                        fill()
                    }
                }
            } else {
                // TEXT FIELD (small) — accumulate until delimiter, then decode
                while findDelimiter() == nil {
                    if eof { break partsLoop }
                    fill()
                }
                guard let hit = findDelimiter() else { break partsLoop }
                let start = buffer.startIndex
                let end = hit.range.lowerBound
                let payloadEnd = end >= 2 ? end - 2 : end
                let partPayload = buffer.subdata(in: start..<payloadEnd)
                
                if let name = fieldName {
                    let text = String(data: partPayload, encoding: .utf8) ?? ""
                    combined[name] = text
                }
                
                // Consume through delimiter and optional "--"
                var consumeTo = hit.range.upperBound
                if hit.isFinal {
                    if buffer.count < consumeTo + 2 { fill() }
                    consumeTo = min(buffer.count, consumeTo + 2)
                }
                if consumeTo > buffer.count { consumeTo = buffer.count }
                buffer.removeSubrange(0..<consumeTo)
                if !hit.isFinal {
                    if buffer.count < 2 { fill() }
                    if buffer.count >= 2, buffer.prefix(2) == crlf {
                        buffer.removeFirst(2)
                    }
                }
                if hit.isFinal { break partsLoop }
            }
        }
    }
    
    
    private func consumeJSON(_ data: Data) {
        
        jsonBody = data
        guard let obj = try? JSONSerialization.jsonObject(with: data),
              let dict = obj as? [String: Any]
        else { return }
        
        if let wVar = try? JSONDecoder().decode(WebVariableTransaction.self, from: data) {
            wVarTransaction = wVar
        }
        
        func flatten(_ dict: [String: Any], prefix: String? = nil) {
            for (key, value) in dict {
                let fullKey = prefix.map { "\($0).\(key)" } ?? key
                switch value {
                    case let s as String:
                        combined[fullKey] = s
                    case let n as NSNumber:
                        combined[fullKey] = n.stringValue
                    case let b as Bool:
                        combined[fullKey] = b.description
                    case let d as Double:
                        combined[fullKey] = String(d)
                    case let sub as [String: Any]:
                        flatten(sub, prefix: fullKey)
                    case let arr as [Any]:
                        let items = arr.compactMap { "\($0)" }
                        combined[fullKey] = items.joined(separator: ",")
                    default:
                        continue
                }
            }
        }
        
        flatten(dict)
    }
    
    private func consumeURLEncoded(_ data: Data) {
        guard let s = String(data: data, encoding: .utf8) else { return }
        let pairs = s.split(separator: "&")
        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let rawKey = String(parts[0])
            let rawVal = String(parts[1])
            let key = rawKey.removingPercentEncoding ?? rawKey
            let val = rawVal.removingPercentEncoding ?? rawVal
            combined[key] = val
        }
    }
    
    // MARK: - In-memory multipart (kept as-is for small requests)
    private func consumeMultipart(_ data: Data, boundary: String) {
        let boundaryPrefix = "--" + boundary
        let boundaryData = boundaryPrefix.data(using: .utf8)!
        let endBoundaryData = ("\r\n" + boundaryPrefix).data(using: .utf8)!
        
        var idx = 0
        
        while idx < data.count {
            guard let startRange = data.range(of: boundaryData, options: [], in: idx..<data.count) else { break }
            idx = startRange.upperBound
            
            // Skip leading CRLF
            if data[idx..<min(idx + 2, data.count)] == "\r\n".data(using: .utf8)! {
                idx += 2
            }
            
            // Find header/body separator
            guard let headerEndRange = data.range(of: "\r\n\r\n".data(using: .utf8)!,
                                                  options: [], in: idx..<data.count) else { break }
            
            let headerData = data[idx..<headerEndRange.lowerBound]
            idx = headerEndRange.upperBound
            
            // Find end of this part
            guard let partEndRange = data.range(of: endBoundaryData, options: [], in: idx..<data.count) else {
                break
            }
            
            let partData = data[idx..<partEndRange.lowerBound]
            idx = partEndRange.lowerBound
            
            // Parse headers
            guard let headerText = String(data: headerData, encoding: .utf8) else { continue }
            var fieldName: String?
            var fileName: String?
            var contentType: String?
            
            for line in headerText.split(separator: "\r\n") {
                let header = String(line)
                if header.lowercased().hasPrefix("content-disposition:") {
                    let parts = header.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
                    for p in parts {
                        if p.hasPrefix("name=") {
                            fieldName = p.split(separator: "=", maxSplits: 1)[1]
                                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        } else if p.hasPrefix("filename=") {
                            fileName = p.split(separator: "=", maxSplits: 1)[1]
                                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        }
                    }
                } else if header.lowercased().hasPrefix("content-type:") {
                    contentType = header.split(separator: ":", maxSplits: 1)[1]
                        .trimmingCharacters(in: .whitespaces)
                }
            }
            
            guard let name = fieldName else { continue }
            
            if let fn = fileName {
                // In-memory path (legacy)
                files[name] = FilePart(fieldName: name, filename: fn, contentType: contentType, data: Data(partData), tempUrl: nil)
            } else if let text = String(data: partData, encoding: .utf8)?.trimmingCharacters(in: .newlines) {
                combined[name] = text
            }
        }
    }
    
    private func boundary(from contentType: String) -> String? {
        let components = contentType.split(separator: ";")
        for comp in components {
            let trimmed = comp.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("boundary=") {
                return String(trimmed.dropFirst("boundary=".count))
            }
        }
        return nil
    }
    
    // MARK: – Accessors
    public func webVariableTransaction() -> WebVariableTransaction? {
        return wVarTransaction
    }
    public func raw(_ key: String) -> Any? {
        if let value = combined[key] {
            return value
        } else if let filePart = files[key] {
            return filePart
        }
        return nil
    }
    public func exists(_ key: String) -> Bool {
        return combined[key] != nil
    }
    public func string(_ key: String) -> String? {
        return combined[key]
    }
    public func int(_ key: String) -> Int? {
        guard let v = combined[key] else { return nil }
        return Int(v)
    }
    public func double(_ key: String) -> Double? {
        guard let v = combined[key] else { return nil }
        return Double(v)
    }
    public func bool(_ key: String) -> Bool? {
        guard let v = combined[key]?.lowercased() else { return nil }
        if v == "true" || v == "1" || v == "on" { return true }
        if v == "false" || v == "0" || v == "off" { return false }
        return Bool(v)
    }
    public func uuid(_ key: String) -> UUID? {
        guard let v = combined[key] else { return nil }
        return UUID(uuidString: v)
    }
    public func file(_ key: String) -> FilePart? {
        return files[key]
    }
    public func object<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = jsonBody else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

