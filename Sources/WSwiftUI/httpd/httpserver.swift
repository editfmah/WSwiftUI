//
//  webserver2.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 28/09/2025.
//
// MicroHTTP.swift
// Swift 6, macOS & Linux (no external deps)

import Foundation

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
}


public enum HttpBody {
    case none
    case inMemory(Data)
    case onDisk(url: URL, size: Int)
}

public struct HttpRequestHead {
    public let method: HttpMethod
    public let uri: String
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
    public init(head: HttpRequestHead, body: HttpBody) {
        self.head = head
        self.body = body
        
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
    
    public enum ContentStyle { case json, html, text, bytes, octetStream }
    @discardableResult public func content(_ style: ContentStyle) -> Self {
        switch style {
            case .json:        return header("Content-Type", "application/json; charset=utf-8")
            case .html:        return header("Content-Type", "text/html; charset=utf-8")
            case .text:        return header("Content-Type", "text/plain; charset=utf-8")
            case .bytes:       return self // caller should set their own type if desired
            case .octetStream: return header("Content-Type", "application/octet-stream")
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
    
    @discardableResult public func body(json object: Any, options: JSONSerialization.WritingOptions = []) -> Self {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: options)
            if headers.first(where: { $0.0.caseInsensitiveCompare("Content-Type") == .orderedSame }) == nil {
                _ = content(.json)
            }
            self.bodyBytes = data
        } catch {
            self.status = .internalError
            _ = content(.text)
            self.bodyBytes = Data("JSON encode error".utf8)
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
        self.append(buffer.bindMemory(to: UInt8.self))
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
        public var maxInMemoryBodyBytes: Int = 2 * 1024 * 1024       // 2 MB
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
        listenFD = socket(AF_INET, Int32(SOCK_STREAM), 0)
        guard listenFD >= 0 else { throw Err.socket(errnoString("socket")) }
        
        var yes: Int32 = 1
        _ = setsockopt(listenFD, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout.size(ofValue: yes)))
        _ = setsockopt(listenFD, IPPROTO_TCP, TCP_NODELAY, &yes, socklen_t(MemoryLayout.size(ofValue: yes)))
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = cfg.port.bigEndian
        addr.sin_addr = in_addr(s_addr: inet_addr(cfg.host))
        let bindOK = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { ptr in
                bind(listenFD, ptr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindOK == 0 else { throw Err.bind(errnoString("bind")) }
        guard listen(listenFD, SOMAXCONN) == 0 else { throw Err.listen(errnoString("listen")) }
        
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
        defer { close(fd) }
        var tv = timeval(tv_sec: Int(cfg.recvTimeoutSeconds), tv_usec: 0)
        _ = setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout.size(ofValue: tv)))
        
        do {
            let head = try readHead(fd: fd)
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
            
            let req = HttpRequest(head: head, body: body)
            var resp = handler(req)
            // Ensure Content-Length
            if resp.headers.first(where: { $0.0.caseInsensitiveCompare("Content-Length") == .orderedSame }) == nil {
                resp.header("Content-Length", "\(resp.bodyBytes.count)")
            }
            // Default Connection: close
            if resp.headers.first(where: { $0.0.caseInsensitiveCompare("Connection") == .orderedSame }) == nil {
                resp.header("Connection", "close")
            }
            try writeResponse(fd: fd, resp: resp)
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
        
        // Decide streaming vs memory
        let shouldStreamToDisk: (Int?) -> Bool = { l in
            if let l = l {
                return l > self.cfg.maxInMemoryBodyBytes
            } else {
                // unknown, chunked; stream when we cross the threshold
                return false
            }
        }
        
        // Prepare temp file lazily (only when needed)
        var tempURL: URL?
        var tempFD: Int32 = -1
        func ensureTempSink() throws {
            if tempFD >= 0 { return }
            let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let url = dir.appendingPathComponent("microhttp-\(UUID().uuidString).upload")
            let path = url.path
            let fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, S_IRUSR | S_IWUSR)
            if fd < 0 { throw Err.io(errnoString("open tmp")) }
            tempURL = url
            tempFD = fd
        }
        
        var inMem = Data()
        inMem.reserveCapacity(min(cfg.maxInMemoryBodyBytes, length ?? (128 * 1024)))
        
        var total = 0
        
        // Helper: write bytes either to memory or to temp when threshold exceeded
        func writeChunk(_ ptr: UnsafeRawBufferPointer) throws {
            total += ptr.count
            if total > cfg.absoluteMaxBodyBytes {
                throw Err.tooLarge
            }
            if tempFD >= 0 {
                // already streaming
                let w = write(tempFD, ptr.baseAddress, ptr.count)
                if w < 0 || w != ptr.count { throw Err.io(errnoString("write tmp")) }
            } else {
                // still in memory
                if inMem.count + ptr.count > cfg.maxInMemoryBodyBytes {
                    // switch to disk
                    try ensureTempSink()
                    // flush what we have
                    try inMem.withUnsafeBytes { old in
                        let w = write(tempFD, old.baseAddress, old.count)
                        if w < 0 || w != old.count { throw Err.io(errnoString("write tmp")) }
                    }
                    inMem.removeAll(keepingCapacity: false)
                    // write current chunk to disk
                    let w = write(tempFD, ptr.baseAddress, ptr.count)
                    if w < 0 || w != ptr.count { throw Err.io(errnoString("write tmp")) }
                } else {
                    inMem.appendBytes(ptr)
                }
            }
        }
        
        // --- Fixed length body
        if let len = length, !isChunked {
            if len == 0 { return .none }
            if shouldStreamToDisk(len) { try ensureTempSink() }
            
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
            if tempFD >= 0 {
                close(tempFD)
                return .onDisk(url: tempURL!, size: total)
            } else {
                return .inMemory(inMem)
            }
        }
        
        // --- Chunked body
        if isChunked {
            // For chunked, we may stay in memory until crossing threshold
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
                        // (optional) could capture trailer headers if needed
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
                // consume \r\n
                var crlf = [UInt8](repeating: 0, count: 2)
                let rr = crlf.withUnsafeMutableBytes { p in
                    read(fd, p.baseAddress, 2)
                }
                if rr != 2 || crlf[0] != 0x0D || crlf[1] != 0x0A {
                    throw Err.parse("chunk CRLF")
                }
            }
            
            if tempFD >= 0 {
                close(tempFD)
                return .onDisk(url: tempURL!, size: total)
            } else {
                return .inMemory(inMem)
            }
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
        if resp.status.code != 204 && resp.status.code != 304 {
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

