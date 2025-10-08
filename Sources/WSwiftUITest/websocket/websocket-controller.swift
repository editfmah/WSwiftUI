//
//  websocket-controller.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 08/10/2025.
//

import Foundation
import WSwiftUI

class WebsocketEndpointExample : CoreWebsocketEndpoint, WebEndpoint, @unchecked Sendable {
    
    var controller: String? = "ws-ping"
    
    var method: String?
    
    override func onOpen(connection: WebSocketConnection, request: HttpRequest) {
        
    }
    
    override func onFrame(connection: WebSocketConnection, frame: WebSocketFrame) -> [WebSocketFrame]? {
        
        return nil
    }
    
    override func onTick(connection: WebSocketConnection) {
        
    }
    
}
