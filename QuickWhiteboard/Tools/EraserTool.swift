//
//  EraserTool.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/10.
//

import Foundation
import AppKit

final class EraserTool: Tool {
    private var _editingItem: ErasedItems? = nil
    var editingItem: (any ToolEditingItem)? {
        _editingItem
    }
    
    func commit(to host: any ToolHost) {
        if let item = _editingItem.take(), !item.selected.isEmpty {
            host.commit(item: item)
        }
    }
    
    private func queryIntersectedItem(location: CGPoint, renderItems: [any RenderItem], eraserRadius: CGFloat) -> RenderItem? {
        for renderItem in renderItems.reversed() {
            if renderItem.hidden || !renderItem.boundingRect.insetBy(dx: -eraserRadius, dy: -eraserRadius).contains(location) {
                continue
            }
            if renderItem is ImageItem && !NSEvent.modifierFlags.contains(.option) {
                continue
            }
            if renderItem.distance(to: location) <=  Float(eraserRadius) {
                return renderItem
            }
        }
        return nil
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        let item = ErasedItems()
        if let renderItem = queryIntersectedItem(location: location, renderItems: host.renderItems, eraserRadius: host.toolbarDataModel.eraserWidth / 2.0) {
            renderItem.hidden = true
            item.selected.append(renderItem)
            host.setNeedsDisplay()
        }
        _editingItem = item
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        commit(to: host)
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        if let item = _editingItem,
           let renderItem = queryIntersectedItem(location: location, renderItems: host.renderItems, eraserRadius: host.toolbarDataModel.eraserWidth / 2.0) {
            renderItem.hidden = true
            item.selected.append(renderItem)
            host.setNeedsDisplay()
        }
    }
    
    func setCursor(host: any ToolHost) {
        let eraserWidth = host.toolbarDataModel.eraserWidth
        let cursorSize = NSSize(width: max(8.0, eraserWidth + 1.0), height: max(8.0, eraserWidth + 1))
        let cursorImage = NSImage(size: cursorSize, flipped: true) { rect in
            let path = NSBezierPath(ovalIn: NSRect(x: (cursorSize.width - eraserWidth) / 2.0, y: (cursorSize.height - eraserWidth) / 2.0, width: eraserWidth, height: eraserWidth))
            path.move(to: NSPoint(x: cursorSize.width / 2.0 - 4.0, y: cursorSize.height / 2.0 - 4.0))
            path.line(to: NSPoint(x: cursorSize.width / 2.0 + 4.0, y: cursorSize.height / 2.0 + 4.0))
            path.move(to: NSPoint(x: cursorSize.width / 2.0 - 4.0, y: cursorSize.height / 2.0 + 4.0))
            path.line(to: NSPoint(x: cursorSize.width / 2.0 + 4.0, y: cursorSize.height / 2.0 - 4.0))
            path.stroke()
            return true
        }
        NSCursor(image: cursorImage, hotSpot: NSPoint(x: cursorSize.width / 2.0, y: cursorSize.height / 2.0)).set()
    }

}
