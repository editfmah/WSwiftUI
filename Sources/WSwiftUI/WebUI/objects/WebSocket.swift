//
//  WebSocket.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 08/10/2025.
//

public extension CoreWebEndpoint {
    /// Creates a WebSocket connection to the given URL and wires up lifecycle handlers.
    /// - Parameters:
    ///   - url: The WebSocket endpoint to connect to (ws:// or wss://).
    ///   - onOpenSocket: Actions to run when the socket opens.
    ///   - onRecieve: Actions to run when a message is received (payload available as window._ws_lastMessage_<id>).
    ///   - onError: Actions to run when an error occurs (details available as window._ws_lastError_<id>).
    @discardableResult
    func WebSocket(url: String, onOpenSocket: [WebAction] = [], onRecieve: [WebAction] = [], onError: [WebAction] = [], onClose: [WebAction] = []) -> WebElement {
        let socket = WebElement()
        populateCreatedObject(socket)
        socket.elementName = "websocket"
        // this is the entire setup and implementation of the websocket connection
        socket.script("""
            const wsUri\(socket.builderId) = "\(url)";
            const websocket\(socket.builderId) = new WebSocket(wsUri\(socket.builderId));
            
            // Expose a helper to send messages from other actions: window.websocketSend_<id>(data)
            function send\(socket.builderId)(data) => {
                try { websocket\(socket.builderId).send(data); } catch (e) { console.error(e); }
            };
            
            websocket\(socket.builderId).addEventListener("open", (event) => {
                \(CompileActions(onOpenSocket, builderId: socket.builderId))
            });
            
            websocket\(socket.builderId).addEventListener("message", (event) => {
                // Stash the last message payload for actions to consume
                var result = event.data;
                \(CompileActions(onRecieve, builderId: socket.builderId))
            });
            
            websocket\(socket.builderId).addEventListener("error", (event) => {
                // Stash error details for actions to consume
                var error = event.error;
                \(CompileActions(onError, builderId: socket.builderId))
            });
            
            websocket\(socket.builderId).addEventListener("close", (event) => {
                \(CompileActions(onClose, builderId: socket.builderId))
            });
            """)
        return socket
    }
}
