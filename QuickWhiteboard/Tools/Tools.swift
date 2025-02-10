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
    func setCursor() -> Void
}

extension Tool {
    func setCursor() {
        NSCursor.crosshair.set()
    }
}
