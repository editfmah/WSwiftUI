//
//  Table.swift
//  SWWebAppServer
//
//  Created by Adrian on 06/07/2025.
//

// 1) Dedicated subclasses for table-related elements
public class WebTableElement: WebCoreElement {}
public class WebTableHeaderElement: WebCoreElement {}
public class WebTableBodyElement: WebCoreElement {}
public class WebTableRowElement: WebCoreElement {}
public class WebTableCellElement: WebCoreElement {}

// 2) Fluent methods for table styling
public extension WebTableElement {
    /// Adds base `table` class
    @discardableResult
    func `default`() -> Self {
        addAttribute(.class("table"))
        return self
    }

    /// Adds striped rows (`.table-striped`)
    @discardableResult
    func striped() -> Self {
        addAttribute(.class("table-striped"))
        return self
    }

    /// Adds borders to all cells (`.table-bordered`)
    @discardableResult
    func bordered() -> Self {
        addAttribute(.class("table-bordered"))
        return self
    }

    /// Adds hover effect on rows (`.table-hover`)
    @discardableResult
    func hover() -> Self {
        addAttribute(.class("table-hover"))
        return self
    }

    /// Makes table more compact (`.table-sm`)
    @discardableResult
    func small() -> Self {
        addAttribute(.class("table-sm"))
        return self
    }
}

// 3) Fluent methods for cell customization
public extension WebTableCellElement {
    /// Sets colspan attribute
    @discardableResult
    func colspan(_ span: Int) -> Self {
        addAttribute(.pair("colspan", "\(span)"))
        return self
    }

    /// Sets rowspan attribute
    @discardableResult
    func rowspan(_ span: Int) -> Self {
        addAttribute(.pair("rowspan", "\(span)"))
        return self
    }

    /// Text alignment ("left", "center", "right") via `.text-*` classes
    @discardableResult
    func align(_ alignment: String) -> Self {
        addAttribute(.class("text-\(alignment)"))
        return self
    }
}

// 4) DSL on BaseWebEndpoint
public extension BaseWebEndpoint {
    // Create overloads
    fileprivate func createTable(_ `init`: (_ element: WebTableElement) -> Void) -> WebTableElement {
        let element = WebTableElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }

    fileprivate func createTableHeader(_ `init`: (_ element: WebTableHeaderElement) -> Void) -> WebTableHeaderElement {
        let element = WebTableHeaderElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }

    fileprivate func createTableBody(_ `init`: (_ element: WebTableBodyElement) -> Void) -> WebTableBodyElement {
        let element = WebTableBodyElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }

    fileprivate func createRow(_ `init`: (_ element: WebTableRowElement) -> Void) -> WebTableRowElement {
        let element = WebTableRowElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }

    fileprivate func createCell(_ `init`: (_ element: WebTableCellElement) -> Void) -> WebTableCellElement {
        let element = WebTableCellElement()
        populateCreatedObject(element)
        `init`(element)
        return element
    }

    /// Builds a `<table>` and applies default `.table` class
    @discardableResult
    func Table(_ content: WebComposerClosure) -> WebTableElement {
        let table = createTable { el in
            el.elementName = "table"
            el.class("table")
        }
        stack.append(table)
        content()
        stack.removeAll(where: { $0.builderId == table.builderId })
        return table
    }

    /// Builds a `<thead>` inside a Table
    @discardableResult
    func TableHeader(_ content: WebComposerClosure) -> WebTableHeaderElement {
        guard let _ = stack.last as? WebTableElement else {
            fatalError("TableHeader must be used inside a Table { ... } block")
        }
        let thead = createTableHeader { el in
            el.elementName = "thead"
        }
        stack.append(thead)
        content()
        stack.removeAll(where: { $0.builderId == thead.builderId })
        return thead
    }

    /// Builds a `<tbody>` inside a Table
    @discardableResult
    func TableBody(_ content: WebComposerClosure) -> WebTableBodyElement {
        guard let _ = stack.last as? WebTableElement else {
            fatalError("TableBody must be used inside a Table { ... } block")
        }
        let tbody = createTableBody { el in
            el.elementName = "tbody"
        }
        stack.append(tbody)
        content()
        stack.removeAll(where: { $0.builderId == tbody.builderId })
        return tbody
    }

    /// Builds a `<tr>` inside a `<thead>` or `<tbody>`
    @discardableResult
    func Row(_ content: WebComposerClosure) -> WebTableRowElement {
        guard (stack.last as? WebTableHeaderElement) != nil || (stack.last as? WebTableBodyElement) != nil else {
            fatalError("Row must be used inside a TableHeader or TableBody block")
        }
        let tr = createRow { el in
            el.elementName = "tr"
        }
        stack.append(tr)
        content()
        stack.removeAll(where: { $0.builderId == tr.builderId })
        return tr
    }

    /// Builds a `<td>` inside a `<tr>` (use `.align()`, `.colspan()`, etc. to customize)
    @discardableResult
    func Cell(_ content: WebComposerClosure) -> WebTableCellElement {
        guard (stack.last as? WebTableRowElement) != nil else {
            fatalError("Cell must be used inside a Row { ... } block")
        }
        let td = createCell { el in
            el.elementName = "td"
        }
        stack.append(td)
        content()
        stack.removeAll(where: { $0.builderId == td.builderId })
        return td
    }
}
