//
//  HttpResponse.swift
//  ZDWeb
//
//  Copyright © 2024 Adrian Herridge, ZestDeck Limited.  All rights reserved.
//


import Foundation

public enum SerializationError: Error {
    case invalidObject
    case notSupported
}

public protocol HttpResponseBodyWriter {
    func write(_ file: String.File) throws
    func write(_ file: String.File, start: Int64, length: Int32) throws
    func write(_ data: [UInt8]) throws
    func write(_ data: ArraySlice<UInt8>) throws
    func write(_ data: NSData) throws
    func write(_ data: Data) throws
}

extension Encodable {
    func toJSONData() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        encoder.dataEncodingStrategy = .base64
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(self)
    }
}

public enum HttpResponseBody {
    
    case json(Encodable)
    case html(String)
    case htmlBody(String)
    case text(String)
    case data(Data,String)
    case custom(Any, (Any) throws -> String)
    
    func content() -> (Int, ((HttpResponseBodyWriter) throws -> Void)?) {
        do {
            switch self {
            case .json(let object):
                if let encoded = object.toJSONData() {
                    return (encoded.count, {
                        try $0.write(encoded)
                    })
                } else {
                    throw SerializationError.invalidObject
                }
                
            case .text(let body):
                let data = [UInt8](body.utf8)
                return (data.count, {
                    try $0.write(data)
                })
            case .html(let html):
                let data = [UInt8](html.utf8)
                return (data.count, {
                    try $0.write(data)
                })
            case .htmlBody(let body):
                let serialised = "<html><meta charset=\"UTF-8\"><body>\(body)</body></html>"
                let data = [UInt8](serialised.utf8)
                return (data.count, {
                    try $0.write(data)
                })
            case .data(let data, _):
                return (data.count, {
                    try $0.write(data)
                })
            case .custom(let object, let closure):
                let serialised = try closure(object)
                let data = [UInt8](serialised.utf8)
                return (data.count, {
                    try $0.write(data)
                })
            }
        } catch {
            let data = [UInt8]("Serialisation error: \(error)".utf8)
            return (data.count, {
                try $0.write(data)
            })
        }
    }
}

// swiftlint:disable cyclomatic_complexity
public enum HttpResponse {
    
    case switchProtocols([String: String], (Socket) -> Void)
    case ok(HttpResponseBody,String?), created, accepted
    case movedPermanently(String)
    case movedTemporarily(String)
    case badRequest(HttpResponseBody?)
    case unauthorized(HttpResponseBody?)
    case forbidden(HttpResponseBody?)
    case notFound
    case busy(HttpResponseBody?)
    case internalServerError
    case raw(Int, String, [String:String]?, ((HttpResponseBodyWriter) throws -> Void)? )
    case redirect(String,String?)
    case tooManyRequests
    
    public var statusCode: Int {
        switch self {
        case .switchProtocols         : return 101
        case .ok                      : return 200
        case .created                 : return 201
        case .accepted                : return 202
        case .movedPermanently        : return 301
        case .redirect                : return 303
        case .movedTemporarily        : return 307
        case .badRequest              : return 400
        case .unauthorized            : return 401
        case .forbidden               : return 403
        case .notFound                : return 404
        case .internalServerError     : return 500
        case .busy                    : return 503
        case .raw(let code, _, _, _)  : return code
        case .tooManyRequests         : return 429
        }
    }
    
    public var reasonPhrase: String {
        switch self {
        case .switchProtocols          : return "Switching Protocols"
        case .ok                       : return "OK"
        case .created                  : return "Created"
        case .accepted                 : return "Accepted"
        case .movedPermanently         : return "Moved Permanently"
        case .movedTemporarily         : return "Moved Temporarily"
        case .badRequest               : return "Bad Request"
        case .unauthorized             : return "Unauthorized"
        case .forbidden                : return "Forbidden"
        case .redirect                 : return "Redirect"
        case .notFound                 : return "Not Found"
        case .internalServerError      : return "Internal Server Error"
        case .busy                     : return "Server Busy"
        case .tooManyRequests          : return "Too many requests"
        case .raw(_, let phrase, _, _) : return phrase
        }
    }
    
    public func headers() -> [(header: String, value: String)] {
        var headers: [(String, String)] = []
        headers.append(("Server", "MyProbation \(HttpServer.VERSION)"))
        switch self {
        case .switchProtocols(let switchHeaders, _):
            for (key, value) in switchHeaders {
                headers.append((key, value))
            }
        case .ok(let body, let authToken):
            switch body {
            case .json: headers.append(("Content-Type","application/json"))
            case .html: headers.append(("Content-Type","text/html"))
            case .data(_,let mime):
                headers.append(("Content-Type",mime))
            default:break
            }
            
            if let cookieAuth = authToken {
                headers.append(("Set-Cookie", "AuthToken=\(cookieAuth); SameSite=Lax; Secure; Path=/; expires=84600;"))
            } else {
                headers.append(("Set-Cookie", "AuthToken=; SameSite=Lax; Secure; Path=/; expires=84600;"))
            }
            
        case .movedPermanently(let location):
            headers.append(("Location",location))
        case .movedTemporarily(let location):
            headers.append(("Location",location))
        case .redirect(let location, let authToken):
            headers.append(("Location",location))
            if let cookieAuth = authToken {
                headers.append(("Set-Cookie", "AuthToken=\(cookieAuth); SameSite=Lax; Secure; Path=/; expires=84600;"))
            } else {
                headers.append(("Set-Cookie", "AuthToken=; SameSite=Lax; Secure; Path=/; expires=84600;"))
            }

        case .raw(_, _, let rawHeaders, _):
            if let rawHeaders = rawHeaders {
                for (key, value) in rawHeaders {
                    headers.append((key,value))
                }
            }
        default:break
        }
        
        return headers
    }
    
    func content() -> (length: Int, write: ((HttpResponseBodyWriter) throws -> Void)?) {
        switch self {
        case .ok(let body, _) : return body.content()
        case .badRequest(let body)     : return body?.content() ?? (-1, nil)
        case .forbidden(let body)     : return body?.content() ?? (-1, nil)
        case .unauthorized(let body)     : return body?.content() ?? (-1, nil)
        case .busy(let body)     : return body?.content() ?? (-1, nil)
        case .raw(_, _, _, let writer) : return (-1, writer)
        default                        : return (-1, nil)
        }
    }
    
    func socketSession() -> ((Socket) -> Void)? {
        switch self {
        case .switchProtocols(_, let handler) : return handler
        default: return nil
        }
    }
}

/**
 Makes it possible to compare handler responses with '==', but
 ignores any associated values. This should generally be what
 you want. E.g.:
 
 let resp = handler(updatedRequest)
 if resp == .NotFound {
 print("Client requested not found: \(request.url)")
 }
 */

func == (inLeft: HttpResponse, inRight: HttpResponse) -> Bool {
    return inLeft.statusCode == inRight.statusCode
}
