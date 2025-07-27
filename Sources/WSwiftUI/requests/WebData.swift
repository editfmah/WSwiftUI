//
//  WebData.swift
//  WSwiftUI
//
//  Created by Adrian on 27/07/2025.
//

import Foundation

public class WebData {
    
    private var combined: [String: String] = [:]

    public struct FilePart {
        public let fieldName: String
        public let filename: String?
        public let contentType: String?
        public let data: Data
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
        let contentType = combined["Content-Type"] ?? ""
        
        if contentType.contains("application/json") {
            consumeJSON(body)
        } else if contentType.contains("application/x-www-form-urlencoded") {
            consumeURLEncoded(body)
        } else if contentType.contains("multipart/form-data"),
                  let boundary = boundary(from: contentType) {
            consumeMultipart(body, boundary: boundary)
        } else {
            if let text = String(data: body, encoding: .utf8) {
                combined["body"] = text
            }
        }
    }

    private func consumeJSON(_ data: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: data),
              let dict = obj as? [String: Any]
        else { return }
        
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
                    let parts = header.split(separator: ";").map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
                    for p in parts {
                        if p.hasPrefix("name=") {
                            fieldName = p.split(separator: "=", maxSplits: 1)[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        } else if p.hasPrefix("filename=") {
                            fileName = p.split(separator: "=", maxSplits: 1)[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        }
                    }
                } else if header.lowercased().hasPrefix("content-type:") {
                    contentType = header.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: CharacterSet.whitespaces)
                }
            }

            guard let name = fieldName else { continue }

            if let fn = fileName {
                files[name] = FilePart(fieldName: name, filename: fn, contentType: contentType, data: Data(partData))
            } else if let text = String(data: partData, encoding: .utf8)?
                        .trimmingCharacters(in: .newlines) {
                combined[name] = text
            }
        }
    }

    private func boundary(from contentType: String) -> String? {
        let components = contentType.split(separator: ";")
        for comp in components {
            let trimmed = comp.trimmingCharacters(in: CharacterSet.whitespaces)
            if trimmed.hasPrefix("boundary=") {
                return String(trimmed.dropFirst("boundary=".count))
            }
        }
        return nil
    }

    // MARK: – Accessors
    
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
        if v == "true" || v == "1" { return true }
        if v == "false" || v == "0" { return false }
        return Bool(v)
    }
    public func uuid(_ key: String) -> UUID? {
        guard let v = combined[key] else { return nil }
        return UUID(uuidString: v)
    }
    public func file(_ key: String) -> FilePart? {
        return files[key]
    }
}
