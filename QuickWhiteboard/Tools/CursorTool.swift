//
//  CursorTool.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/11.
//

import Foundation
import AppKit

private let growingColor = SIMD4<Float>.init(x: 0.0, y: 0.0, z: 0.0, w: 0.5)
private let movingColor = SIMD4<Float>.init(x: 0.2, y: 0.2, z: 1.0, w: 0.8)

private enum CursorState {
    case none
    case growingSelection(rectItem: RectangleItem)
    case movingSelection(movingItem: MovedItems, rectItem: RectangleItem)
}

final class CursorTool: Tool {
    private var state: CursorState = .none

    var editingItem: (any ToolEditingItem)? {
        switch state {
        case .none:
            nil
        case .growingSelection(let rect):
            rect
        case .movingSelection(_, let rect):
            rect
        }
    }

    func commit(to host: any ToolHost) {
        if case let .movingSelection(movingItem, _) = state {
            if movingItem.moved {
                host.commit(item: movingItem)
            } else {
                host.setNeedsDisplay()
            }
        }
        state = .none
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        if case let .movingSelection(_, rect) = state {
            if rect.boundingRect.contains(location) {
                return
            } else {
                commit(to: host)
            }
        }
        for item in host.renderItems.reversed() {
            if !item.hidden && item.distance(to: location) < 1e-2 {
                if item.frozen && !NSEvent.modifierFlags.contains(.option) {
                    continue
                }
                let boundingRect = item.boundingRect
                let rectItem = RectangleItem(strokeColor: movingColor, strokeWidth: 1.0)
                rectItem.globalPosition = boundingRect.origin
                rectItem.to = boundingRect.size.float2
                state = .movingSelection(movingItem: MovedItems(items: [item]), rectItem: rectItem)
                host.setNeedsDisplay()
                return
            }
        }
        let rectItem = RectangleItem(strokeColor: growingColor, strokeWidth: 1.0)
        rectItem.from = location.float2
        rectItem.to = location.float2
        state = .growingSelection(rectItem: rectItem)
        host.setNeedsDisplay()
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        if case let .growingSelection(rectItem) = state {
            let selectionRect = rectItem.boundingRect
            var outlineRect = CGRect.null
            var selectedItems = [any RenderItem]()
            for item in host.renderItems {
                let itemRect = item.boundingRect
                if !item.hidden && selectionRect.intersection(itemRect).equalTo(itemRect) {
                    if item.frozen && !NSEvent.modifierFlags.contains(.option) {
                        continue
                    }
                    selectedItems.append(item)
                    outlineRect = outlineRect.union(itemRect)
                }
            }
            if !selectedItems.isEmpty {
                let rectItem = RectangleItem(strokeColor: movingColor, strokeWidth: 1.0)
                rectItem.globalPosition = outlineRect.origin
                rectItem.to = outlineRect.size.float2
                state = .movingSelection(movingItem: MovedItems(items: selectedItems), rectItem: rectItem)
            } else {
                state = .none
            }
            host.setNeedsDisplay()
        }
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        switch state {
        case .none:
            break
        case .growingSelection(let rect):
            rect.to = location.float2
            host.setNeedsDisplay()
        case .movingSelection(let item, let rect):
            item.update(dx: event.deltaX, dy: -event.deltaY)
            rect.globalPosition.x += event.deltaX
            rect.globalPosition.y += -event.deltaY
            host.setNeedsDisplay()
        }
    }

    func handleDelete(host: any ToolHost) {
        if case let .movingSelection(movingItem, _) = state {
            let erasedItem = ErasedItems()
            erasedItem.selected = movingItem.items
            commit(to: host)
            DispatchQueue.main.async {
                host.commit(item: erasedItem)
            }
        }
    }

    func setCursor(host: any ToolHost) {
        NSCursor.arrow.set()
    }
}
