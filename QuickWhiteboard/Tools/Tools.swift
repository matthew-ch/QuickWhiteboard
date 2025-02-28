//
//  Tools.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/6/9.
//

import Foundation
import AppKit

@MainActor
protocol ToolEditingItem: AnyObject {}

@MainActor
protocol ToolHost: AnyObject {
    func setNeedsDisplay() -> Void
    func commit(item: any ToolEditingItem) -> Void
    var toolbarDataModel: ToolbarDataModel { get }
    func setDefaultTool() -> Void
    var renderItems: [any RenderItem] { get }
}

@MainActor
protocol Tool: AnyObject {
    var editingItem: (any ToolEditingItem)? { get }
    func commit(to host: any ToolHost) -> Void
    func mouseDown(with event: NSEvent, location: CGPoint, host: any ToolHost) -> Void
    func mouseUp(with event: NSEvent, location: CGPoint, host: any ToolHost) -> Void
    func mouseDragged(with event: NSEvent, location: CGPoint, host: any ToolHost) -> Void
    func handleDelete(host: any ToolHost) -> Void
    func setCursor(host: any ToolHost) -> Void
}

extension Tool {
    func handleDelete(host: any ToolHost) {
        // do nothing by default
    }
    func setCursor(host: any ToolHost) {
        let strokeWidth = host.toolbarDataModel.strokeWidth
        let cursorSize = NSSize(width: max(8.0, strokeWidth + 1.0), height: max(8.0, strokeWidth + 1))
        let cursorImage = NSImage(size: cursorSize, flipped: true) { rect in
            let path = NSBezierPath(ovalIn: NSRect(x: (cursorSize.width - strokeWidth) / 2.0, y: (cursorSize.height - strokeWidth) / 2.0, width: strokeWidth, height: strokeWidth))
            path.move(to: NSPoint(x: cursorSize.width / 2.0 - 4.0, y: cursorSize.height / 2.0))
            path.line(to: NSPoint(x: cursorSize.width / 2.0 + 4.0, y: cursorSize.height / 2.0))
            path.move(to: NSPoint(x: cursorSize.width / 2.0, y: cursorSize.height / 2.0 - 4.0))
            path.line(to: NSPoint(x: cursorSize.width / 2.0, y: cursorSize.height / 2.0 + 4.0))
            path.stroke()
            return true
        }
        NSCursor(image: cursorImage, hotSpot: NSPoint(x: cursorSize.width / 2.0, y: cursorSize.height / 2.0)).set()
    }
}
