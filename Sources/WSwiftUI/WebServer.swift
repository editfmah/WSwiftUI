import Foundation
import Dispatch

private extension HttpRequest {
    var authenticationToken: String? {
        get {
            // check the headers for an authentication token
            if let authHeader = self.head.headers.first(where: { $0.0.lowercased() == "authorization" })?.1 {
                // strip the bearer part
                let components = authHeader.split(separator: " ")
                guard components.count == 2, components[0].lowercased() == "bearer" else {
                    return nil
                }
                // return the token part
                return String(components[1])
            }
            // check the query parameters
            if let token = self.head.queryParams["token"] {
                return token
            }
            // check cookies
            if let cookie = self.cookies["auth"] {
                return cookie
            }
            return nil
        }
    }
}

public class WSwiftServer {
    
    // endpoint registration
    private var mutex: Mutex = Mutex()
    private var endpoints: [WebEndpoint] = []
    public func register(_ newEndpoint: WebEndpoint) {
        
        let instance = newEndpoint.create()
        
        // calculate the path from the controller and method
        let path = instance.path
        mutex.execute {
            endpoints.append( instance )
        }
        
        let callback: ((HttpRequest) -> HttpResponse) = { [self] request in
            
            let action = WebRequestActivity.from(request: request)
            var endpoint = newEndpoint.create()
            var grants: [String] = []
            
            endpoint.authenticationIdentifier = request.authenticationToken
            
            if endpoint.authenticationRequired.contains(.authenticated) {
                if let token = request.authenticationToken, let authenticator = self.getUserRoles, let currentGrants = authenticator(token, endpoint) {
                    grants = currentGrants
                    if grants.isEmpty {
                        return HttpResponse().redirect(to: "/")
                            .clearCookie(name: "auth")
                    }
                } else {
                    return HttpResponse().redirect(to: "/")
                        .clearCookie(name: "auth")
                }
            }
            
            // we've passed authentication, next check the permissions for the user vs the required permissions.
            
            if let content = endpoint as? WebContent {
                if let permissions = content.acceptedRoles(for: action) {
                    if permissions.isEmpty == false {
                        // get the authenticated permissions/grants
                        if grants.containsAny(permissions) == false {
                            return HttpResponse().status(.forbidden).body("You do not have permission to perform this action.")
                        }
                    }
                }
            } else if let api = endpoint as? WebApiEndpoint {
                if let permissions = api.acceptedRoles() {
                    if permissions.isEmpty == false {
                        // get the authenticated permissions/grants
                        if grants.containsAny(permissions) == false {
                            return HttpResponse().status(.forbidden).body("You do not have permission to perform this action.")
                        }
                    }
                }
            }
            
            // populate the handler
            endpoint.request = request
            
            // extract any values from the request and put them into the web data object
            endpoint.data.consume(request.head.queryParams)
            endpoint.data.consume(request.head.headerMap)
            endpoint.data.consume(request.body)
            endpoint.ephemeralData["user_roles"] = grants
            
            // build the menu structure
            var menus: [MenuEntry] = []
            mutex.execute {
                
                var available: [WebEndpoint] = []
                
                for (e) in endpoints {
                    
                    if e is MenuIndexable {
                        
                        // we need to check if the endpoint is visible when logged in or logged out
                        if e.authenticationRequired.contains(.authenticated) && grants.isEmpty {
                            continue // skip this item
                        }
                        
                        // check if it's unauthenticated only, but user is logged in
                        if e.authenticationRequired.contains(.unauthenticated) && (e.authenticationRequired.contains(.authenticated) == false) && (grants.isEmpty == false) {
                            continue // skip this item
                        }
                        
                        // we now need to check if we have permissions to see it
                        if e.authenticationRequired.contains(.authenticated) {
                            
                            // cast the object into a cotent or api
                            if let content = e as? WebContent {
                                if let permissions = content.acceptedRoles(for: action) {
                                    if permissions.isEmpty == false {
                                        // get the authenticated permissions/grants
                                        if grants.containsAny(permissions) == false {
                                            continue // skip this item
                                        }
                                    }
                                }
                            }
                            
                        }
                        
                        // we are here so it should be shown in the menu structure, but could be a child of one that does not exist yet. Urgh.
                        available.append(e)
                        
                    }
                    
                }
                
                // now we go through the available endpoints in the tuple and build up the menu structure, and find all the primary entries and create them
                
                var primaries: [String] = []
                
                for e in available {
                    
                    // it has to be content and it has to be indexable
                    guard let menuEndpoint = e as? MenuIndexable else { continue }
                    guard e is WebContent else { continue }
                    
                    if primaries.contains(menuEndpoint.menuPrimary) == false {
                        
                        // we have a new one, we can go ahead and create the primary entry
                        primaries.append(menuEndpoint.menuPrimary)
                        
                        // now the menu entry as well
                        let entry = MenuEntry()
                        entry.title = menuEndpoint.menuPrimary
                        entry.path = e.path
                        
                        menus.append(entry)
                        
                    }
                    
                }
                
                // now we are going to add in secondary entries to the primary ones
                for e in available {
                    
                    guard let menuEndpoint = e as? MenuIndexable else { continue }
                    guard e is WebContent else { continue }
                    
                    // find the primary entry
                    if let primaryEntry = menus.first(where: { $0.title == menuEndpoint.menuPrimary }) {
                        
                        // there must be a secondary title
                        if let secondary = menuEndpoint.menuSecondary, secondary.isEmpty == false {
                            
                            // now we can add the secondary entry
                            let secondaryEntry = MenuEntry()
                            secondaryEntry.title = secondary
                            secondaryEntry.path = e.path
                            secondaryEntry.header = false
                            
                            // now we can add it to the primary entry
                            primaryEntry.children.append(secondaryEntry)
                            
                        }
                        
                    }
                }
            }
            
            if let endpoint = endpoint as? CoreWebEndpoint {
                endpoint.ephemeralData["menu_data"] = menus
            }
            
            // now make the onAccept callback if its setup
            if let onAccept = self.onAccept {
                onAccept(endpoint)
            }
            
            // now execute and return the correct method
            if let endpoint = endpoint as? CoreWebEndpoint {
                
                var response: Any? = nil
                
                if let endpoint = endpoint as? WebApiEndpoint {
                    // execute the api endpoint
                    response = endpoint.call()
                } else if let endpoint = endpoint as? WebContent {
                    // execute the content endpoint
                    switch action {
                        case .Content:
                            response = endpoint.content()
                        case .Persist:
                            response = endpoint.persist()
                    }
                } else {
                    // we don't know what to do with this endpoint, so return not found
                    return HttpResponse().status(.notFound)
                }
                
                // if we have a response, return it
                if let response = response as? HttpResponse {
                    // check to see if there was a new auth token set
                    return response
                } else if response is WebElement {
                    // build the html response from the response object
                    if endpoint is WebContent {
                        let pageContent = endpoint.renderWebPage()
                        return HttpResponse().status(.ok).content(.html).body(pageContent).setCookie(name: "auth", value: endpoint.newAuthenticationIdentifier ?? endpoint.authenticationIdentifier ?? "", path: "/", domain: nil, maxAge: 3600, expires: nil, httpOnly: true, secure: false, sameSite: "Lax")
                    }
                } else if let response = response as? Codable {
                    return HttpResponse().status(.ok).content(.json).body(json: response).setCookie(name: "auth", value: endpoint.newAuthenticationIdentifier ?? endpoint.authenticationIdentifier ?? "", path: "/", domain: nil, maxAge: 3600, expires: nil, httpOnly: true, secure: false, sameSite: "Lax")
                }
                
                return HttpResponse().status(.notFound)
                
            }
            
            return HttpResponse().status(.notFound)
            
        }
        
        svr.addRoute(path, handler: callback)
        print("Registered endpoint \(newEndpoint) at path \(path)")
        
        
    }
    
    public func registerWebSocket(_ newEndpoint: CoreWebsocketEndpoint) {
        let instance = newEndpoint.create()
        // compute path from controller/method if available, otherwise default
        let path: String
        if let endpointWithPath = instance as? WebEndpoint {
            path = endpointWithPath.path
        } else {
            path = "/ws"
        }

        let callback: ((HttpRequest) -> HttpResponse) = { [weak self] request in
            guard let self = self else { return HttpResponse().status(.serviceUnavailable) }
            // Only proceed for websocket upgrade requests
            switch request.kind {
            case .websocket(let upgrade):
                // Create long-lived endpoint instance
                let wsEndpoint = newEndpoint.create()
                wsEndpoint.request = request
                // Select a protocol if needed
                let chosenProto = upgrade.protocols.first
                // Accept handshake
                let response = HttpResponse().acceptWebSocket(key: upgrade.key, protocol: chosenProto)

                // After the HTTP server writes 101, it will not close the fd; we launch the loop
                DispatchQueue.global(qos: .userInitiated).async {
                    wsEndpoint.startWebSocket(upgrade)
                }

                return response
            case .http:
                return HttpResponse().status(.badRequest).body("Expected WebSocket upgrade")
            }
        }

        svr.addRoute(path, handler: callback)
        print("Registered WebSocket endpoint \(newEndpoint) at path \(path)")
    }
    
    public func unregister(_ endpoint: WebEndpoint) {
        
    }
    
    private var getUserRoles: ((String, WebEndpoint) -> [String]?)? = nil
    
    // authentication
    public func onGetUserRoles(callback: @escaping ((_ authenticationToken: String?, _ endpoint: WebEndpoint) -> [String]?)) {
        getUserRoles = callback
    }
    
    // request events
    private var onAccept: ((_ endpoint: WebEndpoint) -> Void)? = nil
    
    public func onAcceptedRequest(callback: @escaping ((_ endpoint: WebEndpoint) -> Void)) {
        self.onAccept = callback
    }
    
    // instance vars
    private var svr: HTTPServer!
    
    // action blocks
    public init(port: Int, bindAddressv4: String? = nil) {
        
        var config = HTTPServer.Config()
        config.port = UInt16(port)

        self.svr = HTTPServer(config: config, onRequestHead: { head in
            return .accept
        }, onBeforeBody: { head in
            return .accept
        }, handler: { request in
            
            if let handler = self.svr.routes[request.head.path] {
                return handler(request)
            }
            
            return HttpResponse().status(.notFound).body("No endpoints configured.")
        })
        
        try? svr.start()

    }
    
}

public class MenuEntry {
    
    public var title: String = ""
    public var children: [MenuEntry] = []
    public var selected: Bool = false
    public var path: String?
    public var header: Bool = false
    
}

internal class Mutex {
    
    private var thread: Thread? = nil;
    private var lock: DispatchQueue
    
    public init() {
        lock = DispatchQueue(label: UUID().uuidString.lowercased())
    }
    
    public func execute(_ closure:() -> Void) {
        if thread != Thread.current {
            lock.sync {
                thread = Thread.current
                closure()
                thread = nil
            }
        } else {
            closure()
        }
    }
    
    public func execute<T>(_ closure:() -> T) -> T {
        if thread != Thread.current {
            return lock.sync {
                thread = Thread.current
                let result = closure()
                thread = nil
                return result
            }
        } else {
            return closure()
        }
    }
    
}
