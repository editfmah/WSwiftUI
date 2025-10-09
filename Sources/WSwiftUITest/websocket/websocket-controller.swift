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
        print("opened websocket")
    }
    
    override func onFrame(connection: WebSocketConnection, frame: WebSocketFrame) -> [WebSocketFrame]? {
        print("recieved datagram")
        return nil
    }
    
    override func onTick(connection: WebSocketConnection) {
        print("onTick sending time")
        try? connection.sendText("{ \"time\" : \"\(Date())\" }")
    }
    
}
