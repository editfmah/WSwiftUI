//
//  main..swift
//  SWWebAppServer
//
//  Created by Adrian on 21/06/2025.
//

import Foundation
import WSwiftUI

let server = WSwiftServer(port: 4242, bindAddressv4: "0.0.0.0")
server.register(HomePage())
server.register(PurposePage())
server.register(ControlsPage())
server.register(ControlsAPI())
server.registerWebSocket(WebsocketEndpointExample())

server.onAcceptedRequest { endpoint in
    
}

server.onGetUserRoles { authenticationToken, endpoint in
    return ["admin"]
}

print("started....")

// now block indefinately allowing the server to run
let semaphore = DispatchSemaphore(value: 0)
semaphore.wait()
