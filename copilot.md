# WSwiftUI Technical Notes

This project is a Swift Package that provides a typed, fluent DSL for building HTML UIs in Swift, then compiling them to HTML + JavaScript at request time.

## Package structure

| Path | Purpose |
| --- | --- |
| `Package.swift` | Declares `WSwiftUI` library and `WSwiftUITest` demo executable. |
| `Sources/WSwiftUI/WebServer.swift` | Endpoint registration, auth/role checks, request dispatch, menu assembly. |
| `Sources/WSwiftUI/endpoints/base/CoreWebEndpoint.swift` | Core element model (`WebElement`), endpoint protocols, shared endpoint state. |
| `Sources/WSwiftUI/endpoints/base/BaseWebEndpoint+Elements.swift` | Core builder plumbing (`populateCreatedObject`, parent stack behavior). |
| `Sources/WSwiftUI/endpoints/base/BaseWebEndpoint+Render.swift` | HTML compiler (attributes + nested element rendering + script emission). |
| `Sources/WSwiftUI/WebUI/objects` | DSL controls/components (Button, Form, Modal, Table, etc.). |
| `Sources/WSwiftUI/WebUI/properties/Properties.swift` | Fluent style/layout modifiers on `WebElement`. |
| `Sources/WSwiftUI/WebUI/actions/Actions.swift` | `WebAction` enum and JS compiler (`CompileActions`). |
| `Sources/WSwiftUI/WebUI/events/Events.swift` | Event listener helpers that emit JS handlers. |
| `Sources/WSwiftUI/WebUI/variables` | Reactive variable primitives (`WString`, `WInt`, etc.) and live-update transport. |
| `Sources/WSwiftUITest` | Demo pages and API/websocket examples showing intended usage. |

## Rendering/build pipeline

1. DSL methods create `WebElement` instances and call `populateCreatedObject`.
2. `populateCreatedObject` assigns a generated `builderId` class and attaches the element under the current stack parent.
3. Container controls push/pop from `stack` so nested closures build correct hierarchy.
4. `renderWebPage()` recursively compiles `WebElement.attributes` into HTML attributes/styles/classes and emits inline scripts.
5. Control behavior is largely encoded as attributes (`.class`, `.style`, `.pair`, `.script`, `.validation`, etc.) that the renderer compiles.

## How controls are currently implemented

Common pattern (good):
- Structural parameters are passed up front in the factory method (for example `Modal(id:)`, `Picker(type:binding:)`, `Form(action:method:)`).
- Optional behavior/styling is chained via fluent modifiers returning `Self`.
- Controls add semantic classes (`wsui-*`) plus Bootstrap classes.

State/binding model:
- `WBool/WInt/WDouble/WString/WArray` produce hidden inputs + generated JS (`updateWebVariable*`, `addCallback*`).
- Bound controls (`TextField`, `Text`, `Toggle`, `Picker`, `ProgressBar`, etc.) read/write through those generated variable functions.
- Validation is encoded with `.validation(...)` attributes and enforced by `Form` client script.

## Current inconsistencies (observed in source)

- Stack unwinding style is mixed: both `removeAll(where: builderId)` and `removeLast()` are used across controls.
- Some controls use typed attributes, others rely heavily on raw `.custom("...")` strings for attributes that could be typed.
- Structural safety is inconsistent: several controls guard misuse with `fatalError`, while others do not enforce parent context.
- Factory style is mixed: some controls use dedicated `createX` helpers, others create `WebElement` directly.
- Layout wrapping is inconsistent (`WrapInLayoutContainer` is used by some controls like `Text`/`Link`/`Toggle`, but not uniformly).

## Preferred implementation direction for new/refactored controls

1. Put structure-defining requirements in the factory signature (tag choice, ids, binding, required mode/type).
2. Put optional style/behavior in fluent modifiers returning `Self`.
3. Encode output via `WebCoreElementAttribute` values wherever possible; use `.custom` only when no typed form exists.
4. Keep parent/child stack behavior deterministic and safe for nested closures.
5. Always attach `wsui-*` class and required semantic/bootstrap classes in the factory so renderer output is deterministic.

### Suggested control template

```swift
public class WebExampleElement: WebElement {}

public extension WebExampleElement {
    @discardableResult
    func variant(_ v: BootstrapVariant) -> Self {
        addAttribute(.class("example-\(v.rawValue)"))
        return self
    }
}

public extension CoreWebEndpoint {
    @discardableResult
    func Example(requiredId: String, _ content: WebComposerClosure) -> WebExampleElement {
        let el = WebExampleElement()
        populateCreatedObject(el)
        el.elementName = "div"
        el.id(requiredId)
        el.class("wsui-example")
        stack.append(el)
        content()
        stack.removeAll(where: { $0.builderId == el.builderId })
        return el
    }
}
```

## AppGrill integration profile (real consumer usage)

`~/src/AppGrill` uses WSwiftUI as the primary UI/web framework (forms, auth pages, admin pages, upload APIs). The implementation there is a practical reference for how this DSL is consumed in production-like code.

### Patterns AppGrill relies on

1. **Server + endpoint model**
   - `WSwiftServer` is instantiated once and endpoints are registered individually (`HomePage`, `LoginPage`, dashboard/admin pages, API endpoints).
   - `onGetUserRoles` returns grants and injects the authenticated domain user into `ephemeralData["user"]`.
   - Endpoint extensions then expose convenience accessors like `thisUser` / `thisAccount`.

2. **Template-first page composition**
   - Every content endpoint renders through a shared `Template { ... }` extension.
   - `Template` sets Bootstrap/CDN head assets, builds navigation from `menuEntries`, and appends a standard footer.
   - App-level UI abstractions are built as endpoint extensions (`Title`, `Container`, `InnerContainer`, `InnerSection`) on top of core WSwiftUI primitives.

3. **Form and validation workflow**
   - Inputs are declared with bound variables (`WString(...).name("field")`, `TextField`, `TextArea`, `Picker`).
   - Validation is duplicated intentionally: client hints via `.validate([...])`, authoritative server checks via `validateData(...)` in `persist()`.
   - On validation failure, pages return `content()` to re-render with ephemeral error/previous value state.

4. **Reactive UI behavior**
   - AppGrill uses `WBool` + `.hidden(...)` + `onValueChange([...])` + `WebAction.if(...)` to drive conditional sections without custom JS files.
   - It uses event/action composition heavily for interaction (`onClick`, hover actions, navigate, setVariable, etc.).

5. **Upload + API pattern**
   - `FileUploader` is used in UI pages with `onUpload` actions (for example redirect/navigate on completion).
   - API endpoints implement `WebApiEndpoint.call()` and consume multipart uploads with `data.file("files[]")`.
   - Binary download is implemented as API endpoint returning `HttpResponse().body(URL(...))`.

6. **Authorization model**
   - `authenticationRequired` controls authenticated vs unauthenticated access.
   - `acceptedRoles(...)`/`acceptedRoles()` controls permission-level authorization for both content and API endpoints.
   - Menu visibility depends on the same authentication/permission checks from `WSwiftServer.register`.

## Compatibility notes from AppGrill usage

- AppGrill source expects uploaded `FilePart` to potentially expose a temp-file URL (`tempUrl`) in addition to in-memory `data`. Preserve/restore this behavior if request parsing is refactored.
- AppGrill also declares an endpoint with `method = "*"`, implying wildcard route expectations for static-like file paths. Route matching behavior should remain compatible with this usage pattern or provide an explicit migration path.

## Practical guidance when evolving WSwiftUI

When changing controls, attributes, renderer behavior, upload handling, or routing semantics, treat AppGrill patterns above as compatibility constraints. The safest path is:
1. keep existing fluent APIs stable,
2. keep bound-variable + form validation behavior stable,
3. keep template/menu/auth integration behavior stable,
4. add new typed attribute helpers where AppGrill currently falls back to raw `.custom(...)`.
