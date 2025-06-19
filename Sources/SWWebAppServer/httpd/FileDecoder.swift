//
//  FileDecoder.swift
//  Squirrel
//
//  Created by Adrian Herridge on 14/06/2019.
//

import Foundation

public class File {
    
    public var name: String?
    public var size: Int?
    public var data: Data?
    public var accountId: UUID?
    public var assetID: UUID?
    public var mimeType: String?
    
}

public func UploadedFile(_ request: HttpRequest) -> File {
    
    let retValue = File()
    
    for m in request.parseMultiPartFormData() {
        
        if m.fileName != nil {
            retValue.name = m.fileName
            retValue.size = m.body.count
            retValue.data = Data(m.body)
            retValue.mimeType = m.type
        } else if m.name! == "accountId" {
            retValue.accountId = UUID(uuidString: String(bytes: m.body, encoding: .ascii) ?? "")
        } else if m.name! == "asset" {
            retValue.assetID = UUID(uuidString: String(bytes: m.body, encoding: .ascii) ?? "")
        }
        
    }
    
    return retValue
    
}


