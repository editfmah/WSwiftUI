//
//  String+Misc.swift
//  ZDWeb
//
//  Copyright © 2024 Adrian Herridge, ZestDeck Limited.  All rights reserved.
//


import Foundation

extension String {
    
    public func unquote() -> String {
        var scalars = self.unicodeScalars
        if scalars.first == "\"" && scalars.last == "\"" && scalars.count >= 2 {
            scalars.removeFirst()
            scalars.removeLast()
            return String(scalars)
        }
        return self
    }
}

extension UnicodeScalar {
    
    public func asWhitespace() -> UInt8? {
        if self.value >= 9 && self.value <= 13 {
            return UInt8(self.value)
        }
        if self.value == 32 {
            return UInt8(self.value)
        }
        return nil
    }
}

extension String {
    
    /// Creates a String by validating the given C‐string pointer is valid UTF‑8.
    /// - Parameter validatingUTF8: A null‑terminated C string (UTF‑8).
    /// - Returns: A String if the C string is valid UTF‑8; otherwise, nil.
    init?(validatingUTF8 cString: UnsafePointer<CChar>?) {
        guard let cString = cString else { return nil }
        let length = strlen(cString)
        let charBuffer = UnsafeBufferPointer(start: cString, count: length)
        let byteArray = charBuffer.map { UInt8(bitPattern: $0) }
        guard let decoded = String(bytes: byteArray, encoding: .utf8) else {
            return nil
        }
        self = decoded
    }
    
    /// Overload: accept a Swift `[CChar]` (must include a 0 terminator, or will use entire array).
    /// - Parameter validatingUTF8: A CChar array containing UTF‑8 bytes.
    init?(validatingUTF8 cChars: [CChar]) {
        // find the first null (0) or use full count
        let length = cChars.firstIndex(of: 0) ?? cChars.count
        let byteArray = cChars[..<length].map { UInt8(bitPattern: $0) }
        guard let decoded = String(bytes: byteArray, encoding: .utf8) else {
            return nil
        }
        self = decoded
    }
    
    /// Overload: accept any `ArraySlice<CChar>` (so you can slice without copying).
    /// - Parameter validatingUTF8: A slice of CChar bytes.
    init?(validatingUTF8 cCharsSlice: ArraySlice<CChar>) {
        let length = cCharsSlice.firstIndex(of: 0).map { $0 - cCharsSlice.startIndex }
        ?? cCharsSlice.count
        let byteArray = cCharsSlice.prefix(length).map { UInt8(bitPattern: $0) }
        guard let decoded = String(bytes: byteArray, encoding: .utf8) else {
            return nil
        }
        self = decoded
    }
}
