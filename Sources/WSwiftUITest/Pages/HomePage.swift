//
//  test+page.swift
//  SWWebAppServer
//
//  Created by Adrian on 21/06/2025.
//

import Foundation
import WSwiftUI

class HomePage : CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]
    
    var menuPrimary: String = "Home"
    
    var menuSecondary: String?
    
    override func content() -> Any? {
        
        Template {
            
            let currentTime = WString("")
            
            HStack {
                Text(currentTime)
            }
            
            WebSocket(url: "ws:/localhost:4242/ws-ping", onRecieve: [
                .extractJSONInto(key: "time", into: currentTime)
            ])
            
            VStack {
                
                Jumbotron(fluid: true) {
                    JumbotronTitle("WSwiftUI")
                    JumbotronSubtitle("A typed Swift framework for building interactive, Bootstrap-style web UIs.")
                }
                
                HStack {}.padding(20)
                
                VStack {
                    Text("About the project").font(.largeTitle).bold().padding(.bottom, 20)
                    
                    Text("WSwiftUI is a lightweight framework allowing you to define HTML pages in Swift using a fluent, type-safe API. ")
                    Text("It handles routing, authentication hooks, server-side DSL for components, and compiles client-side behaviors automatically.")
                    
                    HStack {}.padding(20)
                    
                    Text("There is an extremely strong focus of rapid application development, with the framework trying to handle all of the basics automatically whilst leaving the developer with the ability to override default behaviours at nearly every level.")
                    
                    HStack {}.padding(20)
                    
                    Text("Key features").font(.title).padding(.bottom, 10)
                    Text("   • Type-safe component DSL")
                    Text("   • Built-in Bootstrap 5 integration")
                    Text("   • Reactive variables & data binding")
                    Text("   • Rich client-side actions & events")
                    Text("   • Menu generation & permission filtering")
                }.padding(80).background(.custom("rgba(227, 243, 255, 1)"))
                
                HStack {}.padding(20)
                
                VStack {
                    
                    Text("Getting Started").font(.title).padding(.bottom, 10)
                    
                    Text("1.   Add WSwiftUI to your package dependencies.")
                    Text("2.   Create a Web Endpoint, be it a web page or api method.")
                    Text("3.   Register the endpoint with the server and start it.")
                    Text("4.   Browse to your configured route and enjoy the interractive UI.")
                    
                    Text("Example").font(.title).padding([.top,.bottom], 20)
                    
                    HStack {
                        Code(language: .swift,
"""
// the main server startup
import WSwiftUI

let server = WSwiftServer(port: 4242)
server.register(HomePage())

// now web browsers can connect to http://localhost:4242/home
""")
                    }.padding(30).background(.white)
                    
                    Text("Content Page Example").font(.title).padding([.top,.bottom], 20)
                    
                    HStack {
                        Code(language: .swift, """
class HomePage : BaseWebEndpoint, WebEndpoint, MenuIndexable {
    
    // the framework maintains the menu structures 
    var menuPrimary: String = "Example Page"
    var menuSecondary: String?
    
    override func content() -> Any? {
        Template {
            VStack {
                Jumbotron(fluid: true) {
                    JumbotronTitle("WSwiftUI")
                    JumbotronSubtitle("Hello, World.")
                }
            }.padding(80)
        }
    }
    
    // this example would create an endpoint at http://localhost/example
    var controller: String? = "example"
    var method: String? = nil
    
}
""")
                    }.padding(30).background(.white)
                    
                }.padding(80).background(.custom("rgba(227, 243, 255, 1)"))
                
                
                
            }.padding(80)
            
        }
    }
    
    var controller: String? = nil
    
    var method: String? = nil
    
    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
    
}
