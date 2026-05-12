# WSwiftUI

A Swift package for building server-rendered, interactive web apps with a SwiftUI-style DSL.

WSwiftUI combines:
- A lightweight HTTP/WebSocket server
- Endpoint-based routing
- A fluent HTML/component builder
- Reactive variables for client-side interactivity
- Bootstrap-friendly controls and styling

---

## Table of contents

1. [Requirements](#requirements)
2. [Install](#install)
3. [Quick start](#quick-start)
4. [Core concepts](#core-concepts)
5. [Routing](#routing)
6. [Building UI](#building-ui)
7. [State and data binding](#state-and-data-binding)
8. [Forms, persist, and validation](#forms-persist-and-validation)
9. [Actions and events](#actions-and-events)
10. [API endpoints and uploads](#api-endpoints-and-uploads)
11. [WebSockets](#websockets)
12. [Authentication and authorization](#authentication-and-authorization)
13. [Run the demo app](#run-the-demo-app)
14. [Project layout](#project-layout)

---

## Requirements

- Swift **6.1+**
- macOS **14+** (per `Package.swift`)

---

## Install

Add WSwiftUI to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/editfmah/WSwiftUI.git", branch: "main")
]
```

Then add the product to your target:

```swift
targets: [
    .executableTarget(
        name: "MyWebApp",
        dependencies: [
            .product(name: "WSwiftUI", package: "WSwiftUI")
        ]
    )
]
```

---

## Quick start

Create a content endpoint and register it with `WSwiftServer`:

```swift
import Foundation
import WSwiftUI

final class HomePage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var controller: String? = nil     // "/" route
    var method: String? = nil
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Home"
    var menuSecondary: String? = nil

    override func content() -> Any? {
        return webpage {
            head(.title("WSwiftUI Example"))
            head(.metaViewport(content: "width=device-width, initial-scale=1"))
            head(.styleLink(href: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"))
            head(.script(src: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"))

            VStack {
                Text("Hello from WSwiftUI").font(.largeTitle).bold()
                Text("Your first endpoint is running.")
            }.padding(32)
        }
    }

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}

let server = WSwiftServer(port: 4242, bindAddressv4: "0.0.0.0")
server.register(HomePage())

print("Server running at http://localhost:4242")
DispatchSemaphore(value: 0).wait()
```

---

## Core concepts

### 1. Endpoint-driven app structure

You create classes that conform to:
- `WebEndpoint` + `WebContent` for pages
- `WebEndpoint` + `WebApiEndpoint` for API routes

`controller` and `method` determine the route path.

### 2. Request activity lifecycle

- `GET`/`HEAD` -> `content()`
- `POST`/`PUT`/`PATCH`/`DELETE` -> `persist()` for content endpoints
- `call()` for API endpoints

### 3. Fluent DSL

Elements are composed with closures and then configured with chainable modifiers:

```swift
Text("Profile").font(.title).foreground(.blue).padding(.bottom, 12)
```

---

## Routing

Paths are assembled from `controller` and `method`:

| controller | method | path |
| --- | --- | --- |
| `nil` | `nil` | `/` |
| `"users"` | `nil` | `/users` |
| `"users"` | `"edit"` | `/users/edit` |

Wildcard routes are supported by using `*` in route registration (for example via endpoint `method = "*"`, resulting in paths like `/assets/*`).

Matching behavior:
1. Exact routes are matched first.
2. Wildcard routes are matched next.
3. More specific wildcard patterns win over broader ones.

---

## Building UI

Common layout/content controls include:
- `VStack`, `HStack`, `Spacer`
- `Text`, `Link`, `Image`, `Code`
- `Card`, `Callout`, `Jumbotron`, `Badge`
- `NavBar`, `Footer`
- `Modal`, `OffCanvas`, `Alert`

Use head helpers to configure page metadata and assets:

```swift
head(.title("My App"))
head(.metaViewport(content: "width=device-width, initial-scale=1"))
head(.styleLink(href: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"))
head(.script(src: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"))
```

Useful fluent layout modifiers:
- `padding(...)`, `margin(...)`
- `frame(width:height:minWidth:maxWidth:minHeight:maxHeight:alignment:)`
- `width(...)`, `height(...)`, `minWidth(...)`, `maxWidth(...)`
- `background(...)`, `foreground(...)`, `opacity(...)`

---

## State and data binding

Create reactive variables with `WBool`, `WInt`, `WDouble`, `WString`, `WArray`.

```swift
let name = WString("").name("name")
let wantsNewsletter = WBool(false).name("newsletter")
let pickerValue = WString("free").name("plan")

TextField("Name", text: name, prompt: "Jane Doe")
Toggle("Subscribe to newsletter", isOn: wantsNewsletter)

Picker("Plan", selection: pickerValue, style: .segmented(.primary)) {
    Text("Free").value("free")
    Text("Pro").value("pro")
}

Text("Welcome $0", name)
```

You can react to variable updates:

```swift
name.onValueChange([
    .text(ref: "live_name", "Name updated")
])
```

---

## Forms, persist, and validation

`Form` automatically wires browser-side validation from `.validate(...)` modifiers.

```swift
override func content() -> Any? {
    let email = WString("").name("email")
    let password = WString("").name("password")

    return webpage {
        Form(action: self.path, method: .post) {
            TextField("Email", text: email, type: .email, prompt: "name@company.com")
                .validate([.notEmpty, .validEmail])

            SecureField("Password", text: password, prompt: "Required")
                .validate([.notEmpty, .atLeast(8)])

            Button("Sign in", type: "submit").variant(.primary)
        }
    }
}

override func persist() -> Any? {
    guard let email = data.string("email"),
          let password = data.string("password"),
          !email.isEmpty,
          !password.isEmpty else {
        return redirect(self.path)
    }

    return HttpResponse().status(.ok).body("Signed in")
}
```

---

## Actions and events

Attach behavior with event helpers like `onClick`, `onChange`, `onInput`, etc.  
Actions are declared with `WebAction`.

```swift
let showModal = WBool(false)

Button("Open modal")
    .variant(.primary)
    .onClick(.setVariable(showModal, to: true))

Modal(id: "welcomeModal", isPresented: showModal) {
    ModalDialog {
        ModalContent {
            ModalHeader {
                ModalTitle {
                    Text("Welcome")
                }
            }
            ModalBody {
                Text("This modal is driven by a bound variable.")
            }
        }
    }
}
```

State-driven overloads are available for:
- `Modal(id:isPresented:...)`
- `Sheet(isPresented:...)`
- `OffCanvas(id:isPresented:...)`
- `Alert(_:isPresented:...)`

---

## API endpoints and uploads

Implement an API endpoint with `WebApiEndpoint`:

```swift
final class UploadAPI: CoreWebEndpoint, WebEndpoint, WebApiEndpoint {
    var controller: String? = "api"
    var method: String? = "upload"
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    func call() -> Any? {
        guard let file = data.file("files[]"),
              let bytes = file.data else {
            return HttpResponse().status(.badRequest).body("No file")
        }

        return HttpResponse().status(.ok).body("Received \(bytes.count) bytes")
    }

    func acceptedRoles() -> [String]? {
        return []
    }
}
```

Client-side uploader:

```swift
FileUploader(action: "/api/upload") {
    Text("Drop files here")
}
```

---

## WebSockets

Server endpoint:

```swift
final class TimeSocket: CoreWebsocketEndpoint, WebEndpoint {
    var controller: String? = "ws-time"
    var method: String? = nil

    override func onTick(connection: WebSocketConnection) {
        try? connection.sendText("{\"time\":\"\(Date())\"}")
    }
}
```

Client usage in page DSL:

```swift
let currentTime = WString("")

Text("Server time: $0", currentTime)
WebSocket(url: "ws://localhost:4242/ws-time", onRecieve: [
    .extractJSONInto(key: "time", into: currentTime)
])
```

---

## Authentication and authorization

Use `authenticationRequired` on endpoints and role callbacks on the server:

```swift
server.onGetUserRoles { token, endpoint in
    guard token != nil else { return nil }
    return ["admin"]
}
```

In content endpoints:
- `acceptedRoles(for: .Content)` and `acceptedRoles(for: .Persist)` can return role requirements.

In API endpoints:
- `acceptedRoles()` can return role requirements.

`MenuIndexable` endpoints are also filtered by auth/roles when the menu tree is built.

---

## Run the demo app

This repository includes an executable demo target:

```bash
swift run WSwiftUITest
```

Then open: `http://localhost:4242`

---

## Project layout

| Path | Purpose |
| --- | --- |
| `Sources/WSwiftUI/WebServer.swift` | Server setup, endpoint registration, auth hooks, dispatch |
| `Sources/WSwiftUI/endpoints` | Endpoint base types and protocol contracts |
| `Sources/WSwiftUI/WebUI/objects` | UI/component DSL (forms, layout, modal, picker, etc.) |
| `Sources/WSwiftUI/WebUI/properties` | Fluent visual/layout modifiers |
| `Sources/WSwiftUI/WebUI/actions` | `WebAction` behavior model |
| `Sources/WSwiftUI/WebUI/events` | Event listener helpers |
| `Sources/WSwiftUI/WebUI/variables` | Reactive variable primitives and live-update wiring |
| `Sources/WSwiftUITest` | Demo app with pages, API endpoint, and WebSocket example |

---

## Development notes

- Prefer passing structure-defining inputs in factory methods (for example `Modal(id:...)`, `Picker(selection:...)`).
- Use fluent modifiers for styling and optional behavior.
- Name bound variables used in forms (`.name("fieldName")`) so values are posted as expected.
- Keep Bootstrap JS/CSS available if you use Bootstrap-dependent components (modal, offcanvas, dropdowns, etc.).
