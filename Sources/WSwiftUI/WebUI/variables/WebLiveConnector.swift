//
//  WebLiveConnector.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 10/08/2025.
//

import Foundation

/// Heterogeneous JSON value for `[String: JSONValue]` maps.
public enum JSONValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let i = try? c.decode(Int.self) { self = .int(i); return }
        if let d = try? c.decode(Double.self) { self = .double(d); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let a = try? c.decode([JSONValue].self) { self = .array(a); return }
        if let o = try? c.decode([String: JSONValue].self) { self = .object(o); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON value")
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .int(let v):    try c.encode(v)
        case .double(let v): try c.encode(v)
        case .bool(let v):   try c.encode(v)
        case .array(let v):  try c.encode(v)
        case .object(let v): try c.encode(v)
        case .null:          try c.encodeNil()
        }
    }
}

/// Payload for live variable read/write.
public final class WebVariableTransaction: Codable {
    public var reference: String
    public var read: Bool
    public var write: Bool
    public var delay: Int?          // optional; omit if unused
    public var data: [String: JSONValue]

    public init(reference: String,
                read: Bool,
                write: Bool,
                delay: Int? = nil,
                data: [String: JSONValue]) {
        self.reference = reference
        self.read = read
        self.write = write
        self.delay = delay
        self.data = data
    }
}
