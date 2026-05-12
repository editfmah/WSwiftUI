//
//  controls-test.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 10/08/2025.
//

import Foundation
import WSwiftUI

private struct UploadResult: Codable {
    var ok: Bool
    var filename: String?
    var size: Int
    var contentType: String?
}

class ControlsAPI: CoreWebEndpoint, WebEndpoint, WebApiEndpoint {
    func call() -> Any? {
        if let request = data.file("files[]") {
            let result = UploadResult(
                ok: true,
                filename: request.filename,
                size: request.data?.count ?? 0,
                contentType: request.contentType
            )
            return HttpResponse().status(.ok).content(.json).body(json: result)
        }
        let result = UploadResult(ok: false, filename: nil, size: 0, contentType: nil)
        return HttpResponse().status(.badRequest).content(.json).body(json: result)
    }

    func acceptedRoles() -> [String]? {
        return []
    }

    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]
    var controller: String? = "api"
    var method: String? = "controls"
}
