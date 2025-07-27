import Foundation

private extension HttpRequest {
    var authenticationToken: String? {
        get {
            // check the headers for an authentication token
            if let authHeader = self.headers["Authorization"] {
                // strip the bearer part
                let components = authHeader.split(separator: " ")
                guard components.count == 2, components[0].lowercased() == "bearer" else {
                    return nil
                }
                // return the token part
                return String(components[1])
            }
            // check the query parameters
            if let token = self.queryparams["token"] {
                return token
            }
            // check cookies
            if let cookie = self.cookieData()["AuthToken"] {
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
            
            if endpoint.authenticationRequired.contains(.authenticated) {
                if let token = request.authenticationToken, let authenticator = self.getUserRoles, let currentGrants = authenticator(token, endpoint) {
                    grants = currentGrants
                } else {
                    return .forbidden(.text("Authentication failed. Please log in again."))
                }
            }
            
            // we've passed authentication, next check the permissions for the user vs the required permissions.
            
            if let content = endpoint as? WebContentEndpoint {
                if let permissions = content.acceptedRoles(for: action) {
                    if permissions.isEmpty == false {
                        // get the authenticated permissions/grants
                        if grants.containsAny(permissions) == false {
                            return .forbidden(.text("You do not have permission to perform this action."))
                        }
                    }
                }
            } else if let api = endpoint as? WebApiEndpoint {
                if let permissions = api.acceptedRoles() {
                    if permissions.isEmpty == false {
                        // get the authenticated permissions/grants
                        if grants.containsAny(permissions) == false {
                            return .forbidden(.text("You do not have permission to perform this action."))
                        }
                    }
                }
            }
            
            // populate the handler
            endpoint.request = request
            
            // extract any values from the request and put them into the web data object
            endpoint.data.consume(request.queryparams)
            endpoint.data.consume(request.headers)
            endpoint.data.consume(request.body)
            
            if var contentEndpoint = endpoint as? WebContentEndpoint {
                // set the content handler
                contentEndpoint.ephemeralData["user_roles"] = grants
            }
            
            // build the menu structure
            var menus: [MenuEntry] = []
            mutex.execute {
                
                var available: [WebEndpoint] = []
                
                for (e) in endpoints {
                    
                    if e is MenuIndexable {
                        
                        // we now need to check if we have permissions to see it
                        if e.authenticationRequired.contains(.unauthenticated) == false {
                            
                            // cast the object into a cotent or api
                            if let content = e as? WebContentEndpoint {
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
                    guard e is WebContentEndpoint else { continue }
                    
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
                    guard e is WebContentEndpoint else { continue }
                    
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
                
                switch action {
                    case .Content:
                        response = endpoint.content()
                    case .View:
                        response = endpoint.view()
                    case .Modify:
                        response = endpoint.modify()
                    case .New:
                        response = endpoint.new()
                    case .Save:
                        response = endpoint.save()
                    case .Delete:
                        response = endpoint.delete()
                    case .Raw:
                        response = endpoint.raw()
                }
                
                // if we have a response, return it
                if let response = response as? HttpResponse {
                    // check to see if there was a new auth token set
                    return response
                } else if response is WebCoreElement {
                    // build the html response from the response object
                    if endpoint is WebContentEndpoint {
                        let pageContent = endpoint.renderWebPage()
                        return HttpResponse.ok(.html(pageContent), endpoint.newAuthenticationIdentifier ?? endpoint.newAuthenticationIdentifier)
                    }
                } else if let response = response as? Codable {
                    return HttpResponse.ok(.json(response), endpoint.newAuthenticationIdentifier ?? endpoint.authenticationIdentifier)
                }
                
                return .notFound
                
            }
            
            return .notFound
            
        }
        
        svr.get[path] = callback
        svr.post[path] = callback
        svr.delete[path] = callback
        svr.patch[path] = callback
        svr.options[path] = callback
        svr.head[path] = callback
        print("Registered endpoint \(newEndpoint) at path \(path)")
        
        
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
    private var port: UInt16
    private var svr: HttpServer
    
    
    // action blocks
    public init(port: Int, bindAddressv4: String? = nil) {
        
        self.port = UInt16(port)
        self.svr = HttpServer()
        #if os(OSX)
        self.svr.listenAddressIPv4 = bindAddressv4 ?? "127.0.0.1"
        #endif
        try? self.svr.start(self.port, forceIPv4: true, priority: .userInteractive)
        
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
