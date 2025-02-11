//
//  EraserTool.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/10.
//

import Foundation
import AppKit

let eraserRadius = 5.0

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
    
    private func queryIntersectedItem(location: CGPoint, renderItems: [any RenderItem]) -> RenderItem? {
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
        if let renderItem = queryIntersectedItem(location: location, renderItems: host.renderItems) {
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
           let renderItem = queryIntersectedItem(location: location, renderItems: host.renderItems) {
            renderItem.hidden = true
            item.selected.append(renderItem)
            host.setNeedsDisplay()
        }
    }
    
    func setCursor() {
        let image = NSImage(systemSymbolName: ToolIdentifier.eraser.symbolName, accessibilityDescription: nil)!
        NSCursor(image: image, hotSpot: CGPoint.from(image.size.float2 / 2.0)).set()
    }

}
