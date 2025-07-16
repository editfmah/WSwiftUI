//
//  test+page.swift
//  SWWebAppServer
//
//  Created by Adrian on 21/06/2025.
//

import Foundation
import SWWebAppServer

class HomePage : BaseWebEndpoint, WebEndpoint, WebContentEndpoint, MenuIndexable {
    
    var menuPrimary: String = "Home"
    
    var menuSecondary: String?
    
    
    override func content() -> Any? {
        
        template {
            
            VStack {
                
                Jumbotron(fluid: true) {
                    JumbotronTitle("WSwiftUI")
                    JumbotronSubtitle("A typed Swift framework for building interactive, Bootstrap-style web UIs.")
                }
                
                HStack {}.padding(20)
                
                Text("About the project").font(.largeTitle)
                
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
                
            }.padding(80)
            
            
            
            VStack {
                VStack {
                    // Project Description
                    Text("About the Project")
                        .class("h2 mt-4 mb-3")
                    
                    
                    // Features
                    Text("Key Features")
                        .class("h3 mt-4 mb-2")
                    ListGroup {
                        ListGroupItem("Type-safe component DSL")
                        ListGroupItem("Built-in Bootstrap 5 integration")
                        ListGroupItem("Reactive variables & data binding")
                        ListGroupItem("Rich client-side actions & events")
                        ListGroupItem("Menu generation & permission filtering")
                    }
                    
                    // Getting Started
                    Text("Getting Started")
                        .class("h3 mt-4 mb-2")
                    Text("1. Add SWWebAppServer to your Swift Package dependencies.")
                    Text("2. Define a subclass of BaseWebEndpoint and implement content() using the DSL.")
                    Text("3. Register your endpoint in main.swift and run the server.")
                    Text("4. Browse to your configured route and enjoy the interactive UI.")
                    
                    // Code example
                    Text("Example Usage")
                        .class("h3 mt-4 mb-2")
                    Card {
                        CardBody {
                            Text("```swift")
                            Text("class MyPage: BaseWebEndpoint {\n    override func content() -> WebCoreElement {\n        webpage {\n            Jumbotron { JumbotronTitle(\"Hello\") }\n        }\n    }\n}```")
                        }
                    }
                    
                    // Links & Resources
                    Text("Resources")
                        .class("h3 mt-4 mb-2")
                    HStack {
                        Link("https://github.com/yourorg/SwiftWebDSL", title: "GitHub Repository", target: "_blank")
                        Spacer()
                        Link("https://docs.example.com/SwiftWebDSL", title: "Documentation", target: "_blank")
                    }
                }
                .padding(20)
            }
        }
    }
    
    var controller: String? = nil
    
    var method: String? = nil
    
    var authenticationRequired: Bool = false
    
    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
    
}
