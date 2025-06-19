//
//  String+BASE64.swift
//  ZDWeb
//
//  Copyright © 2024 Adrian Herridge, ZestDeck Limited.  All rights reserved.
//


import Foundation

extension String {
    
    public static func toBase64(_ data: [UInt8]) -> String {
        return Data(data).base64EncodedString()
    }
}
