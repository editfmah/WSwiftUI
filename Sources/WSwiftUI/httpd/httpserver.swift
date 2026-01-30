//
//  webserver2.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 28/09/2025.
//
// MicroHTTP.swift
// Swift 6, macOS & Linux (no external deps)

import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

// MARK: - Errors

public enum Err: Error, CustomStringConvertible {
    case socket(String)
    case bind(String)
    case listen(String)
    case accept(String)
    case io(String)
    case parse(String)
    case closed
    case rejected                      // gatekeeper rejected
    case timeout
    case tooLarge                      // body exceeded allowed limits
    case unsupported(String)
    
    public var description: String {
        switch self {
            case .socket(let s): return "Socket error: \(s)"
            case .bind(let s): return "Bind error: \(s)"
            case .listen(let s): return "Listen error: \(s)"
            case .accept(let s): return "Accept error: \(s)"
            case .io(let s): return "IO error: \(s)"
            case .parse(let s): return "Parse error: \(s)"
            case .closed: return "Connection closed"
            case .rejected: return "Rejected by gatekeeper"
            case .timeout: return "Timeout"
            case .tooLarge: return "Body too large"
            case .unsupported(let s): return "Unsupported: \(s)"
        }
    }
}

// MARK: - Request/Response models

@frozen
public struct HttpMethod: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String
    
    @inlinable
    public init(_ v: String) {
        // Locale-invariant uppercasing to keep it deterministic
        self.rawValue = v.uppercased(with: Locale(identifier: "en_US_POSIX"))
    }
    
    @inlinable
    public init(rawValue: String) {
        self.init(rawValue)
    }
    
    // Static singletons (now concurrency-safe because the type is Sendable)
    public static let GET:    Self = .init("GET")
    public static let POST:   Self = .init("POST")
    public static let PUT:    Self = .init("PUT")
    public static let DELETE: Self = .init("DELETE")
    public static let PATCH:  Self = .init("PATCH")
    public static let HEAD:   Self = .init("HEAD")
    public static let OPTIONS: Self = .init("OPTIONS")
}

@frozen
public struct HttpStatus: Equatable, Hashable, Sendable {
    public let code: Int
    public let reason: String
    
    @inlinable
    public init(_ code: Int, _ reason: String) {
        self.code = code
        self.reason = reason
    }
    
    // Common statuses (concurrency-safe because HttpStatus is Sendable)
    public static let ok                 = HttpStatus(200, "OK")
    public static let created            = HttpStatus(201, "Created")
    public static let accepted           = HttpStatus(202, "Accepted")
    public static let noContent          = HttpStatus(204, "No Content")
    public static let redirect           = HttpStatus(302, "Redirect")
    public static let notModified        = HttpStatus(304, "Not Modified")
    public static let badRequest         = HttpStatus(400, "Bad Request")
    public static let unauthorized       = HttpStatus(401, "Unauthorized")
    public static let forbidden          = HttpStatus(403, "Forbidden")
    public static let notFound           = HttpStatus(404, "Not Found")
    public static let payloadTooLarge    = HttpStatus(413, "Payload Too Large")
    public static let unsupportedType    = HttpStatus(415, "Unsupported Media Type")
    public static let expectationFailed  = HttpStatus(417, "Expectation Failed")
    public static let internalError      = HttpStatus(500, "Internal Server Error")
    public static let serviceUnavailable = HttpStatus(503, "Service Unavailable")
    public static let switchingProtocols = HttpStatus(101, "Switching Protocols")
}


public enum HttpBody {
    case none
    case inMemory(Data)
}

public enum RequestKind: Sendable {
    case http
    case websocket(WebSocketUpgrade)
}

public struct WebSocketUpgrade: Sendable {
    public let key: String
    public let protocols: [String]
    public let version: Int?
    public let extensions: String?
    public let socketFD: Int32
}

public struct HttpRequestHead {
    public let method: HttpMethod
    public let uri: String
    public var path: String {
        get {
            // this could be "/auth-password?email=adrian@uncia.co.uk", return only the path part
            let u = uri.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: true).first ?? Substring("")
            return "\(u)"
        }
    }
    public let version: String
    public let headers: [(String, String)]
    public var headerMap: [String:String] {
        var m: [String:String] = [:]
        for (k,v) in headers { m[k.lowercased()] = v }
        return m
    }
    public var contentLength: Int? {
        if let s = headerMap["content-length"], let n = Int(s) { return n }
        return nil
    }
    public var isChunked: Bool {
        headerMap["transfer-encoding"]?.lowercased().contains("chunked") == true
    }
    public var expectContinue: Bool {
        headerMap["expect"]?.lowercased().contains("100-continue") == true
    }
    public var pathComponents: [String] {
        let u = uri.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: true).first ?? Substring("")
        return u.split(separator: "/", omittingEmptySubsequences: true).map { String($0) }
    }
    public var queryParams: [String:String] {
        get {
            var out: [String:String] = [:]
            let parts = uri.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else { return out }
            let query = parts[1]
            for kv in query.split(separator: "&") {
                let pair = kv.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
                if pair.count == 2 {
                    let key = String(pair[0]).removingPercentEncoding ?? String(pair[0])
                    let val = String(pair[1]).removingPercentEncoding ?? String(pair[1])
                    out[key] = val
                } else if pair.count == 1 {
                    let key = String(pair[0]).removingPercentEncoding ?? String(pair[0])
                    out[key] = ""
                }
            }
            return out
        }
    }
}

public final class HttpRequest {
    public let head: HttpRequestHead
    public let body: HttpBody
    public let kind: RequestKind
    public init(head: HttpRequestHead, body: HttpBody, kind: RequestKind) {
        self.head = head
        self.body = body
        self.kind = kind
    }
    public convenience init(head: HttpRequestHead, body: HttpBody) {
        self.init(head: head, body: body, kind: .http)
    }
    public var cookies: [String:String] {
        guard let raw = head.headerMap["cookie"] else { return [:] }
        var out: [String:String] = [:]
        for part in raw.split(separator: ";") {
            let kv = part.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if kv.count == 2 { out[kv[0]] = kv[1] }
        }
        return out
    }
    
    /// Decode JSON from the request body
    public func decodeBody<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let data: Data
        switch body {
        case .none:
            throw Err.parse("No body to decode")
        case .inMemory(let d):
            data = d
        }
        return try decoder.decode(type, from: data)
    }
}

public final class HttpResponse {
    
    public private(set) var status = HttpStatus.ok
    public private(set) var headers: [(String, String)] = []
    public private(set) var bodyBytes: Data = Data()
    public private(set) var bodyFileUrl: URL?
    public private(set) var bodyFileHandleRange: Range<Int>?
    
    public init() {}
    
    // Fluent
    @discardableResult public func status(_ s: HttpStatus) -> Self { self.status = s; return self }
    @discardableResult public func header(_ k: String, _ v: String) -> Self { headers.append((k, v)); return self }
    @discardableResult public func headers(_ items: [(String,String)]) -> Self { headers.append(contentsOf: items); return self }
    
    public enum ImageType {
        case jpg
        case png
        case svg
        case custom(String)
        var contentType: String {
            switch self {
                case .jpg:
                    return "image/jpeg"
                case .png:
                    return "image/png"
                case .svg:
                    return "image/svg+xml"
                case .custom(let s):
                    return s
            }
        }
    }
    
    public enum ContentStyle { case json, html, text, bytes, octetStream, image(ImageType) }
    @discardableResult public func content(_ style: ContentStyle) -> Self {
        switch style {
            case .json:        return header("Content-Type", "application/json; charset=utf-8")
            case .html:        return header("Content-Type", "text/html; charset=utf-8")
            case .text:        return header("Content-Type", "text/plain; charset=utf-8")
            case .bytes:       return self // caller should set their own type if desired
            case .octetStream: return header("Content-Type", "application/octet-stream")
            case .image(let type):
                return header("Content-Type", type.contentType)
        }
    }
    
    // Auto body -> sets Content-Type if not present and defaults status to .ok
    @discardableResult public func body(_ s: String) -> Self {
        if headers.first(where: { $0.0.caseInsensitiveCompare("Content-Type") == .orderedSame }) == nil {
            _ = content(.text)
        }
        self.bodyBytes = Data(s.utf8)
        return self
    }
    
    @discardableResult public func body<T: Encodable>(json object: T, encoder: JSONEncoder = JSONEncoder()) -> Self {
        do {
            let data = try encoder.encode(object)
            if headers.first(where: { $0.0.caseInsensitiveCompare("Content-Type") == .orderedSame }) == nil {
                _ = content(.json)
            }
            self.bodyBytes = data
        } catch {
            self.status = .internalError
            _ = content(.text)
            self.bodyBytes = Data("JSON encode error: \(error.localizedDescription)".utf8)
        }
        return self
    }
    
    @discardableResult public func body(_ data: Data) -> Self {
        if headers.first(where: { $0.0.caseInsensitiveCompare("Content-Type") == .orderedSame }) == nil {
            _ = content(.octetStream)
        }
        self.status = .ok
        self.bodyBytes = data
        return self
    }
    
    @discardableResult public func body(_ file: URL, from: Int? = nil, to: Int? = nil) -> Self {
        // we will pass the file URL directly for super efficient streaming of binary data so it doesn't have to be read into memory before transmission
        self.bodyFileUrl = file
        if let from, let to {
            self.bodyFileHandleRange = from..<to
        }
        return self
    }
    
    // Cookies
    @discardableResult public func setCookie(
        name: String, value: String,
        path: String = "/", domain: String? = nil,
        maxAge: Int? = nil, expires: Date? = nil,
        httpOnly: Bool = true, secure: Bool = false, sameSite: String? = "Lax"
    ) -> Self {
        var parts = ["\(name)=\(value)"]
        parts.append("Path=\(path)")
        if let d = domain { parts.append("Domain=\(d)") }
        if let a = maxAge { parts.append("Max-Age=\(a)") }
        if let e = expires {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.timeZone = TimeZone(secondsFromGMT: 0)
            fmt.dateFormat = "E, dd MMM yyyy HH:mm:ss 'GMT'"
            parts.append("Expires=\(fmt.string(from: e))")
        }
        if httpOnly { parts.append("HttpOnly") }
        if secure { parts.append("Secure") }
        if let ss = sameSite { parts.append("SameSite=\(ss)") }
        headers.append(("Set-Cookie", parts.joined(separator: "; ")))
        return self
    }
    
    @discardableResult public func clearCookie(name: String, path: String = "/", domain: String? = nil) -> Self {
        let past = Date(timeIntervalSince1970: 0)
        return setCookie(name: name, value: "", path: path, domain: domain, maxAge: 0, expires: past, httpOnly: true, secure: false, sameSite: "Lax")
    }
    
    @discardableResult public func redirect(to url: String, permanent: Bool = false) -> Self {
        self.status = permanent ? HttpStatus(301, "Moved Permanently") : HttpStatus(302, "Found")
        _ = header("Location", url)
        return self
    }
    
    @discardableResult public func acceptWebSocket(key: String, protocol proto: String? = nil) -> Self {
        self.status = .switchingProtocols
        _ = header("Upgrade", "websocket")
        _ = header("Connection", "Upgrade")
        let accept = wsAcceptKey(for: key)
        _ = header("Sec-WebSocket-Accept", accept)
        if let proto, !proto.isEmpty { _ = header("Sec-WebSocket-Protocol", proto) }
        return self
    }
    
}

// MARK: - Gatekeeper decisions

extension HttpRequestHead: Sendable {}
extension HttpMethod: Sendable {}
extension HttpStatus: Sendable {}

extension HttpRequest: @unchecked Sendable {}
extension HttpResponse: @unchecked Sendable {}

public enum GateDecision: Sendable {
    case accept
    case reject(HttpResponse)
}

public typealias HeadCallback       = @Sendable (HttpRequestHead) -> GateDecision
public typealias BeforeBodyCallback = @Sendable (HttpRequestHead) -> GateDecision
public typealias Handler            = @Sendable (HttpRequest) -> HttpResponse


// MARK: - Thread Pool (low-overhead on top of GCD)

final class ThreadPool {
    private let queues: [DispatchQueue]
    private var idx = 0
    private let lock = NSLock()
    
    init(workers: Int) {
        let n = max(1, workers)
        var qs: [DispatchQueue] = []
        qs.reserveCapacity(n)
        for i in 0..<n {
            qs.append(DispatchQueue(label: "microhttp.worker.\(i)", qos: .userInitiated, attributes: .concurrent))
        }
        self.queues = qs
    }
    
    // NOTE: Mark the closure as @Sendable
    func submit(_ work: @escaping @Sendable () -> Void) {
        lock.lock()
        let q = queues[idx]
        idx = (idx + 1) % queues.count
        lock.unlock()
        q.async(execute: work)
    }
}

// MARK: - Utilities

@inline(__always)
private func errnoString(_ where_: String) -> String {
    let e = errno
    return "\(where_): \(String(cString: strerror(e))) [errno \(e)]"
}

private extension Data {
    mutating func appendBytes(_ buffer: UnsafeRawBufferPointer) {
        if let base = buffer.baseAddress {
            self.append(base.assumingMemoryBound(to: UInt8.self), count: buffer.count)
        }
    }
}

// MARK: - WebSocket helpers

fileprivate func wsAcceptKey(for clientKey: String) -> String {
    let magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    let combined = Data((clientKey + magic).utf8)
    let digest = SHA1.hash(data: combined)
    return digest.base64EncodedString()
}

// Minimal SHA1 implementation in pure Swift (no external deps)
fileprivate struct SHA1 {
    static func hash(data: Data) -> Data {
        var message = [UInt8](data)
        let ml = UInt64(message.count * 8)
        // append the bit '1' to the message
        message.append(0x80)
        // append 0 <= k < 512 bits '0', so that the resulting message length (in bits)
        // is congruent to 448 (mod 512)
        while (message.count % 64) != 56 { message.append(0) }
        // append length as 64-bit big-endian
        var mlBE = ml.bigEndian
        withUnsafeBytes(of: &mlBE) { message.append(contentsOf: $0) }
        
        var h0: UInt32 = 0x67452301
        var h1: UInt32 = 0xEFCDAB89
        var h2: UInt32 = 0x98BADCFE
        var h3: UInt32 = 0x10325476
        var h4: UInt32 = 0xC3D2E1F0
        
        var w = [UInt32](repeating: 0, count: 80)
        for chunkStart in stride(from: 0, to: message.count, by: 64) {
            // Break chunk into sixteen 32-bit big-endian words w[0..15]
            for i in 0..<16 {
                let j = chunkStart + i*4
                let b0 = UInt32(message[j]) << 24
                let b1 = UInt32(message[j+1]) << 16
                let b2 = UInt32(message[j+2]) << 8
                let b3 = UInt32(message[j+3])
                w[i] = b0 | b1 | b2 | b3
            }
            // Extend to 80 words
            for i in 16..<80 {
                let v = w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16]
                w[i] = (v << 1) | (v >> 31)
            }
            
            var a = h0
            var b = h1
            var c = h2
            var d = h3
            var e = h4
            
            for i in 0..<80 {
                var f: UInt32 = 0
                var k: UInt32 = 0
                switch i {
                    case 0...19:
                        f = (b & c) | ((~b) & d)
                        k = 0x5A827999
                    case 20...39:
                        f = b ^ c ^ d
                        k = 0x6ED9EBA1
                    case 40...59:
                        f = (b & c) | (b & d) | (c & d)
                        k = 0x8F1BBCDC
                    default:
                        f = b ^ c ^ d
                        k = 0xCA62C1D6
                }
                let temp = ((a << 5) | (a >> 27)) &+ f &+ e &+ k &+ w[i]
                e = d
                d = c
                c = (b << 30) | (b >> 2)
                b = a
                a = temp
            }
            
            h0 = h0 &+ a
            h1 = h1 &+ b
            h2 = h2 &+ c
            h3 = h3 &+ d
            h4 = h4 &+ e
        }
        
        var digest = Data()
        for h in [h0, h1, h2, h3, h4] {
            var be = h.bigEndian
            withUnsafeBytes(of: &be) { digest.appendBytes($0) }
        }
        return digest
    }
}

// MARK: - WebSocket framing & connection

public enum WebSocketOpcode: UInt8, Sendable {
    case continuation = 0x0
    case text        = 0x1
    case binary      = 0x2
    // 0x3-0x7 reserved
    case close       = 0x8
    case ping        = 0x9
    case pong        = 0xA
    // 0xB-0xF reserved
}

public struct WebSocketFrame: Sendable {
    public var fin: Bool
    public var opcode: WebSocketOpcode
    public var payload: Data
    public var maskingKey: UInt32? // network-order key if present
    
    public init(fin: Bool, opcode: WebSocketOpcode, payload: Data = Data(), maskingKey: UInt32? = nil) {
        self.fin = fin
        self.opcode = opcode
        self.payload = payload
        self.maskingKey = maskingKey
    }
}

public final class WebSocketConnection: @unchecked Sendable {
    
    internal var endpoint: CoreWebsocketEndpoint?
    public let fd: Int32
    private let writeLock = NSLock()
    
    public init(fd: Int32) {
        self.fd = fd
    }
    
    deinit {
        // no implicit close; caller owns lifecycle
    }
    
    // MARK: - I/O primitives
    
    private func readExact(_ count: Int) throws -> Data {
        var remaining = count
        var out = Data()
        out.reserveCapacity(count)
        var buf = [UInt8](repeating: 0, count: min(64 * 1024, max(1024, count)))
        while remaining > 0 {
            let toRead = min(buf.count, remaining)
            let r = buf.withUnsafeMutableBytes { p in
                read(fd, p.baseAddress, toRead)
            }
            if r == 0 { throw Err.closed }
            if r < 0 { throw Err.io(errnoString("ws read")) }
            out.append(contentsOf: buf[0..<r])
            remaining -= r
        }
        return out
    }
    
    private func writeAll(_ data: Data) throws {
        try data.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
            var base = p.baseAddress!
            var remaining = p.count
            while remaining > 0 {
                let w = write(fd, base, remaining)
                if w < 0 { throw Err.io(errnoString("ws write")) }
                remaining -= w
                base = base.advanced(by: w)
            }
        }
    }
    
    // MARK: - Framing
    
    private func unmask(_ data: inout Data, key: UInt32) {
        var k = key
        data.withUnsafeMutableBytes { (p: UnsafeMutableRawBufferPointer) in
            guard let base = p.baseAddress else { return }
            var ptr = base.assumingMemoryBound(to: UInt8.self)
            let count = p.count
            for i in 0..<count {
                let j = i & 3
                let shift = (3 - j) * 8
                let maskByte = UInt8((k >> shift) & 0xFF)
                ptr[i] ^= maskByte
            }
        }
    }
    
    private func serialize(frame: WebSocketFrame, mask: Bool = false) -> Data {
        var out = Data()
        let finBit: UInt8 = frame.fin ? 0x80 : 0x00
        let opcodeNibble: UInt8 = frame.opcode.rawValue & 0x0F
        var b0 = finBit | opcodeNibble
        withUnsafeBytes(of: &b0) { out.append($0.bindMemory(to: UInt8.self).baseAddress!, count: 1) }
        
        var payload = frame.payload
        var maskBit: UInt8 = mask ? 0x80 : 0x00
        let len = payload.count
        if len <= 125 {
            var bLen = maskBit | UInt8(len)
            withUnsafeBytes(of: &bLen) { out.append($0.bindMemory(to: UInt8.self).baseAddress!, count: 1) }
        } else if len <= 0xFFFF {
            var b126 = maskBit | 126
            withUnsafeBytes(of: &b126) { out.append($0.bindMemory(to: UInt8.self).baseAddress!, count: 1) }
            var be = UInt16(len).bigEndian
            withUnsafeBytes(of: &be) { out.append($0.bindMemory(to: UInt8.self).baseAddress!, count: 2) }
        } else {
            var b127 = maskBit | 127
            withUnsafeBytes(of: &b127) { out.append($0.bindMemory(to: UInt8.self).baseAddress!, count: 1) }
            var be = UInt64(len).bigEndian
            withUnsafeBytes(of: &be) { out.append($0.bindMemory(to: UInt8.self).baseAddress!, count: 8) }
        }
        
        var maskingKey: UInt32 = 0
        if mask {
            maskingKey = frame.maskingKey ?? UInt32.random(in: UInt32.min...UInt32.max)
            var be = maskingKey.bigEndian
            withUnsafeBytes(of: &be) { out.append($0.bindMemory(to: UInt8.self).baseAddress!, count: 4) }
            // apply masking to payload copy
            var copy = payload
            unmask(&copy, key: maskingKey)
            out.append(copy)
        } else {
            out.append(payload)
        }
        
        return out
    }
    
    // Reads a single raw frame (may be a fragment)
    private func readFrame() throws -> WebSocketFrame {
        let header = try readExact(2)
        let b0 = header[header.startIndex]
        let b1 = header[header.startIndex.advanced(by: 1)]
        let fin = (b0 & 0x80) != 0
        let opcodeRaw = b0 & 0x0F
        guard let opcode = WebSocketOpcode(rawValue: opcodeRaw) else { throw Err.parse("ws opcode") }
        let masked = (b1 & 0x80) != 0
        var length = Int(b1 & 0x7F)
        if length == 126 {
            let ext = try readExact(2)
            let val = ext.withUnsafeBytes { $0.load(as: UInt16.self) }
            length = Int(UInt16(bigEndian: val))
        } else if length == 127 {
            let ext = try readExact(8)
            let val = ext.withUnsafeBytes { $0.load(as: UInt64.self) }
            let be = UInt64(bigEndian: val)
            // clamp to Int
            if be > UInt64(Int.max) { throw Err.tooLarge }
            length = Int(be)
        }
        var maskingKey: UInt32? = nil
        if masked {
            let keyData = try readExact(4)
            let k = keyData.withUnsafeBytes { $0.load(as: UInt32.self) }
            maskingKey = UInt32(bigEndian: k)
        }
        var payload = length > 0 ? try readExact(length) : Data()
        if let key = maskingKey {
            unmask(&payload, key: key)
        }
        return WebSocketFrame(fin: fin, opcode: opcode, payload: payload, maskingKey: maskingKey)
    }
    
    // Reads a complete message (handles fragmentation for text/binary)
    public func readMessage() throws -> WebSocketFrame {
        var first = try readFrame()
        switch first.opcode {
            case .text, .binary:
                if first.fin { return first }
                // accumulate continuation frames
                var data = first.payload
                while true {
                    let cont = try readFrame()
                    guard cont.opcode == .continuation else { throw Err.parse("ws continuation expected") }
                    data.append(cont.payload)
                    if cont.fin { break }
                }
                return WebSocketFrame(fin: true, opcode: first.opcode, payload: data, maskingKey: nil)
            case .continuation:
                throw Err.parse("unexpected continuation start")
            case .ping, .pong, .close:
                return first
        }
    }
    
    // MARK: - Public send helpers (servers do not mask)
    
    public func send(frame: WebSocketFrame) throws {
        // As a server, do not mask outgoing frames per RFC6455
        let data = serialize(frame: frame, mask: false)
        try writeAll(data)
    }
    
    public func sendText(_ text: String) throws {
        try send(frame: WebSocketFrame(fin: true, opcode: .text, payload: Data(text.utf8)))
    }
    
    public func sendBinary(_ data: Data) throws {
        try send(frame: WebSocketFrame(fin: true, opcode: .binary, payload: data))
    }
    
    public func sendPing(_ data: Data = Data()) throws {
        let payload = data.prefix(125) // control frames max 125
        try send(frame: WebSocketFrame(fin: true, opcode: .ping, payload: payload))
    }
    
    public func sendPong(_ data: Data = Data()) throws {
        let payload = data.prefix(125)
        try send(frame: WebSocketFrame(fin: true, opcode: .pong, payload: payload))
    }
    
    public func close(code: UInt16 = 1000, reason: String = "") throws {
        var payload = Data()
        var be = code.bigEndian
        withUnsafeBytes(of: &be) { payload.append($0.bindMemory(to: UInt8.self).baseAddress!, count: 2) }
        payload.append(reason.data(using: .utf8) ?? Data())
        payload = payload.prefix(125)
        try send(frame: WebSocketFrame(fin: true, opcode: .close, payload: payload))
    }
    
    // MARK: - Run loop
    
    public typealias FrameHandler = @Sendable (WebSocketFrame) -> [WebSocketFrame]?
    
    // Runs a blocking loop reading frames and invoking the handler. Returns on close or error.
    public func run(handle: FrameHandler) throws {
        loop: while true {
            let frame = try readMessage()
            switch frame.opcode {
                case .ping:
                    // if handler returns nothing, auto-pong
                    if let responses = handle(frame) {
                        for r in responses { try send(frame: r) }
                    } else {
                        try sendPong(frame.payload)
                    }
                case .close:
                    // echo close if handler doesn't override
                    if let responses = handle(frame) {
                        for r in responses { try send(frame: r) }
                    } else {
                        // attempt to echo and then break
                        try send(frame: WebSocketFrame(fin: true, opcode: .close, payload: frame.payload))
                    }
                    break loop
                default:
                    if let responses = handle(frame) {
                        for r in responses { try send(frame: r) }
                    }
            }
        }
    }
}

// MARK: - Server

public final class HTTPServer: @unchecked Sendable {
    
    public typealias HeadCallback = (HttpRequestHead) -> GateDecision
    public typealias BeforeBodyCallback = (HttpRequestHead) -> GateDecision
    public typealias Handler = (HttpRequest) -> HttpResponse
    
    public struct Config {
        public var host: String = "0.0.0.0"
        public var port: UInt16 = 8080
        public var workers: Int = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)
        public var recvTimeoutSeconds: Int32 = 60
        public var absoluteMaxBodyBytes: Int = 1_000_000_000          // 1 GB safety
        public init() {}
    }
    
    internal var routes: [String: ((HttpRequest) -> HttpResponse)] = [:]
    
    public func addRoute(_ path: String, handler: @escaping (HttpRequest) -> HttpResponse) {
        routes[path] = handler
    }
    
    private let cfg: Config
    private let onHead: HeadCallback
    private let onBeforeBody: BeforeBodyCallback
    private let handler: Handler
    private var listenFD: Int32 = -1
    private let pool: ThreadPool
    private let acceptQueue = DispatchQueue(label: "microhttp.accept", qos: .userInitiated)
    
    public init(
        config: Config = Config(),
        onRequestHead: @escaping HeadCallback,
        onBeforeBody: @escaping BeforeBodyCallback,
        handler: @escaping Handler
    ) {
        self.cfg = config
        self.onHead = onRequestHead
        self.onBeforeBody = onBeforeBody
        self.handler = handler
        self.pool = ThreadPool(workers: config.workers)
    }
    
    public func start() throws {
#if os(Linux)
        let sockType = CInt(SOCK_STREAM.rawValue)
#else
        let sockType = CInt(SOCK_STREAM)
#endif
        listenFD = socket(AF_INET, sockType, 0)
        guard listenFD >= 0 else { throw Err.socket(errnoString("socket")) }
        
        var yes: Int32 = 1
        _ = setsockopt(listenFD, CInt(SOL_SOCKET), CInt(SO_REUSEADDR), &yes, socklen_t(MemoryLayout.size(ofValue: yes)))
        _ = setsockopt(listenFD, CInt(IPPROTO_TCP), CInt(TCP_NODELAY), &yes, socklen_t(MemoryLayout.size(ofValue: yes)))
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = cfg.port.bigEndian
        let saddr = cfg.host.withCString { inet_addr($0) }
        addr.sin_addr = in_addr(s_addr: saddr)
        let bindOK = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { ptr in
                bind(listenFD, ptr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindOK == 0 else { throw Err.bind(errnoString("bind")) }
        guard listen(listenFD, CInt(SOMAXCONN)) == 0 else { throw Err.listen(errnoString("listen")) }
        
        acceptQueue.async { [weak self] in
            self?.acceptLoop()
        }
    }
    
    public func stop() {
        if listenFD >= 0 { close(listenFD); listenFD = -1 }
    }
    
    private func acceptLoop() {
        while listenFD >= 0 {
            var addr = sockaddr()
            var len: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
            let fd = accept(listenFD, &addr, &len)
            if fd < 0 {
                // benign EINTR etc.
                continue
            }
            pool.submit { [weak self] in
                self?.handleConnection(fd: fd)
            }
        }
    }
    
    private func handleConnection(fd: Int32) {
        var shouldClose = true
        defer { if shouldClose { close(fd) } }
        var tv = timeval(tv_sec: Int(cfg.recvTimeoutSeconds), tv_usec: 0)
        _ = setsockopt(fd, CInt(SOL_SOCKET), CInt(SO_RCVTIMEO), &tv, socklen_t(MemoryLayout.size(ofValue: tv)))
        
        do {
            let head = try readHead(fd: fd)
            
            let hm = head.headerMap
            let connectionHeader = hm["connection"]?.lowercased() ?? ""
            let upgradeHeader = hm["upgrade"]?.lowercased() ?? ""
            var reqKind: RequestKind = .http
            if connectionHeader.contains("upgrade") && upgradeHeader == "websocket" {
                if let key = hm["sec-websocket-key"] {
                    let protos = (hm["sec-websocket-protocol"] ?? "")
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    let ver = Int(hm["sec-websocket-version"] ?? "")
                    let ext = hm["sec-websocket-extensions"]
                    reqKind = .websocket(WebSocketUpgrade(key: key, protocols: protos, version: ver, extensions: ext, socketFD: fd))
                }
            }
            
            // Gate 1 (immediately after headers)
            switch onHead(head) {
                case .accept:
                    break
                case .reject(let resp):
                    try writeResponse(fd: fd, resp: resp)
                    return
            }
            
            // Gate 2 (before reading body) lets you reject based on length/type
            switch onBeforeBody(head) {
                case .accept:
                    break
                case .reject(let resp):
                    try writeResponse(fd: fd, resp: resp)
                    return
            }
            
            let body = try readBody(fd: fd, head: head)
            
            let req = HttpRequest(head: head, body: body, kind: reqKind)
            var resp = handler(req)
            // Ensure Content-Length, skip for 101 Switching Protocols
            if resp.status.code != 101 {
                if resp.headers.first(where: { $0.0.caseInsensitiveCompare("Content-Length") == .orderedSame }) == nil {
                    resp.header("Content-Length", "\(resp.bodyBytes.count)")
                }
            }
            // Default Connection: close, skip for 101 Switching Protocols
            if resp.status.code != 101 {
                if resp.headers.first(where: { $0.0.caseInsensitiveCompare("Connection") == .orderedSame }) == nil {
                    resp.header("Connection", "close")
                }
            }
            try writeResponse(fd: fd, resp: resp)
            
            if resp.status.code == 101 {
                shouldClose = false
                return
            }
        } catch let e as Err {
            // best-effort 400/413/500 depending
            let resp: HttpResponse
            switch e {
                case .tooLarge:
                    resp = HttpResponse().status(.payloadTooLarge).content(.text).body("Payload too large")
                case .parse, .unsupported:
                    resp = HttpResponse().status(.badRequest).content(.text).body("Bad request")
                default:
                    resp = HttpResponse().status(.internalError).content(.text).body("Internal error")
            }
            _ = try? writeResponse(fd: fd, resp: resp)
        } catch {
            let resp = HttpResponse().status(.internalError).content(.text).body("Internal error")
            _ = try? writeResponse(fd: fd, resp: resp)
        }
    }
    
    // MARK: - Parsing
    
    private func readLineCRLF(fd: Int32, limit: Int = 16 * 1024) throws -> String {
        var data = Data()
        var lastWasCR = false
        var buf = [UInt8](repeating: 0, count: 1)
        while data.count < limit {
            let r = buf.withUnsafeMutableBytes { ptr in
                read(fd, ptr.baseAddress, 1)
            }
            if r == 0 { throw Err.closed }
            if r < 0 { throw Err.io(errnoString("read line")) }
            let b = buf[0]
            if lastWasCR && b == 0x0A { // \n
                data.removeLast() // remove the CR we appended previously
                break
            }
            data.append(b)
            lastWasCR = (b == 0x0D) // \r
        }
        guard let s = String(data: data, encoding: .utf8) else { throw Err.parse("line utf8") }
        return s
    }
    
    private func readHead(fd: Int32) throws -> HttpRequestHead {
        // Request line
        let requestLine = try readLineCRLF(fd: fd)
        let parts = requestLine.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 3 else { throw Err.parse("request line") }
        let method = HttpMethod(String(parts[0]))
        let uri = String(parts[1])
        let version = String(parts[2])
        
        // Headers
        var headers: [(String,String)] = []
        while true {
            let line = try readLineCRLF(fd: fd)
            if line.isEmpty { break } // CRLF terminator reached
            guard let idx = line.firstIndex(of: ":") else { throw Err.parse("header colon") }
            let key = String(line[..<idx]).trimmingCharacters(in: .whitespaces)
            let val = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
            headers.append((key, val))
        }
        
        return HttpRequestHead(method: method, uri: uri, version: version, headers: headers)
    }
    
    // MARK: - Body reader (FINISHED)
    
    private func readBody(fd: Int32, head: HttpRequestHead) throws -> HttpBody {
        // Only read body for methods that can have one
        let method = head.method
        let mayHaveBody = !(method == .GET || method == .HEAD)
        if !mayHaveBody { return .none }

        let isChunked = head.isChunked
        let length = head.contentLength

        // Quick rejections
        if let len = length, len > cfg.absoluteMaxBodyBytes {
            throw Err.tooLarge
        }

        // If content-length unknown and not chunked => no body (or unsupported)
        if length == nil && !isChunked {
            return .none
        }

        var inMem = Data()
        inMem.reserveCapacity(min(16 * 1024 * 1024, length ?? (128 * 1024)))

        var total = 0

        func writeChunk(_ ptr: UnsafeRawBufferPointer) throws {
            total += ptr.count
            if total > cfg.absoluteMaxBodyBytes {
                throw Err.tooLarge
            }
            inMem.appendBytes(ptr)
        }

        // --- Fixed length body
        if let len = length, !isChunked {
            if len == 0 { return .none }

            var remaining = len
            let bufSize = min(64 * 1024, max(8 * 1024, len))
            var buf = [UInt8](repeating: 0, count: bufSize)
            while remaining > 0 {
                let toRead = min(buf.count, remaining)
                let r = buf.withUnsafeMutableBytes { p in
                    read(fd, p.baseAddress, toRead)
                }
                if r == 0 { throw Err.closed }
                if r < 0 { throw Err.io(errnoString("read body")) }
                try buf.withUnsafeBytes { p in
                    try writeChunk(UnsafeRawBufferPointer(start: p.baseAddress, count: r))
                }
                remaining -= r
            }
            return .inMemory(inMem)
        }

        // --- Chunked body
        if isChunked {
            let bufCap = 64 * 1024
            var buf = [UInt8](repeating: 0, count: bufCap)

            func readLine() throws -> String {
                try readLineCRLF(fd: fd)
            }

            while true {
                // chunk size line (hex; may include extensions after ';')
                let sizeLine = try readLine()
                let hexPart = sizeLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: true).first ?? Substring("")
                guard let chunkSize = Int(hexPart, radix: 16) else { throw Err.parse("chunk size") }
                if chunkSize == 0 {
                    // read trailing headers until empty line
                    while true {
                        let l = try readLine()
                        if l.isEmpty { break }
                    }
                    break
                }
                var remaining = chunkSize
                while remaining > 0 {
                    let toRead = min(buf.count, remaining)
                    let r = buf.withUnsafeMutableBytes { p in
                        read(fd, p.baseAddress, toRead)
                    }
                    if r == 0 { throw Err.closed }
                    if r < 0 { throw Err.io(errnoString("read chunk")) }
                    try buf.withUnsafeBytes { p in
                        try writeChunk(UnsafeRawBufferPointer(start: p.baseAddress, count: r))
                    }
                    remaining -= r
                }
                // trailing CRLF after each chunk
                var crlf = [UInt8](repeating: 0, count: 2)
                let rr = crlf.withUnsafeMutableBytes { p in
                    read(fd, p.baseAddress, 2)
                }
                if rr != 2 || crlf[0] != 0x0D || crlf[1] != 0x0A {
                    throw Err.parse("chunk CRLF")
                }
            }

            return .inMemory(inMem)
        }

        // Fallback
        return .none
    }
    
    // MARK: - Response writer
    
    private func writeAll(fd: Int32, _ data: Data) throws {
        try data.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
            var base = p.baseAddress!
            var remaining = p.count
            while remaining > 0 {
                let w = write(fd, base, remaining)
                if w < 0 { throw Err.io(errnoString("write")) }
                remaining -= w
                base = base.advanced(by: w)
            }
        }
    }
    
    private func writeAll(fd: Int32, _ ptr: UnsafeRawBufferPointer) throws {
        var base = ptr.baseAddress!
        var remaining = ptr.count
        while remaining > 0 {
            let w = write(fd, base, remaining)
            if w < 0 { throw Err.io(errnoString("write")) }
            remaining -= w
            base = base.advanced(by: w)
        }
    }
    
    private func writeResponse(fd: Int32, resp: HttpResponse) throws {
        var head = "HTTP/1.1 \(resp.status.code) \(resp.status.reason)\r\n"
        var headers = resp.headers
        if headers.first(where: { $0.0.caseInsensitiveCompare("Date") == .orderedSame }) == nil {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.timeZone = TimeZone(secondsFromGMT: 0)
            fmt.dateFormat = "E, dd MMM yyyy HH:mm:ss 'GMT'"
            headers.append(("Date", fmt.string(from: Date())))
        }
        if headers.first(where: { $0.0.caseInsensitiveCompare("Server") == .orderedSame }) == nil {
            headers.append(("Server", "MicroHTTP/1.0"))
        }
        // check to see if there is a content range specified for file responses
        if let url = resp.bodyFileUrl, let range = resp.bodyFileHandleRange {
            let fileSize: Int
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: url.path)
                fileSize = attr[.size] as? Int ?? 0
            } catch {
                fileSize = 0
            }
            headers.append(("Content-Range", "bytes \(range.lowerBound)-\(range.upperBound - 1)/\(fileSize)"))
            headers.append(("Content-Length", "\(range.count)"))
        }
        for (k,v) in headers {
            head += "\(k): \(v)\r\n"
        }
        head += "\r\n"
        try writeAll(fd: fd, Data(head.utf8))
        if resp.status.code != 204 && resp.status.code != 304 && resp.status.code != 101 {
            if let url = resp.bodyFileUrl {
                if let range = resp.bodyFileHandleRange {
                    let handle = try FileHandle(forReadingFrom: url)
                    try handle.seek(toOffset: UInt64(range.lowerBound))
                    var remaining = range.count
                    let bufSize = min(64 * 1024, max(8 * 1024, remaining))
                    var buf = [UInt8](repeating: 0, count: bufSize)
                    while remaining > 0 {
                        let toRead = min(buf.count, remaining)
                        let r = buf.withUnsafeMutableBytes { p in
                            read(handle.fileDescriptor, p.baseAddress, toRead)
                        }
                        if r == 0 { break } // EOF
                        if r < 0 { throw Err.io(errnoString("read file")) }
                        try buf.withUnsafeBytes { p in
                            try writeAll(fd: fd, UnsafeRawBufferPointer(start: p.baseAddress, count: r))
                        }
                        remaining -= r
                    }
                } else {
                    let handle = try FileHandle(forReadingFrom: url)
                    let fileSize = try handle.seekToEnd()
                    try handle.seek(toOffset: 0)
                    var remaining = Int(fileSize)
                    let bufSize = min(64 * 1024, max(8 * 1024, remaining))
                    var buf = [UInt8](repeating: 0, count: bufSize)
                    while remaining > 0 {
                        let toRead = min(buf.count, remaining)
                        let r = buf.withUnsafeMutableBytes { p in
                            read(handle.fileDescriptor, p.baseAddress, toRead)
                        }
                        if r == 0 { break } // EOF
                        if r < 0 { throw Err.io(errnoString("read file")) }
                        try buf.withUnsafeBytes { p in
                            try writeAll(fd: fd, UnsafeRawBufferPointer(start: p.baseAddress, count: r))
                        }
                        remaining -= r
                    }
                }
            } else {
                try writeAll(fd: fd, resp.bodyBytes)
            }
        }
    }
}

