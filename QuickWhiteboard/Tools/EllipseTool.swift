//
//  EllipseTool.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/10.
//

import Foundation
import AppKit

final class EllipseTool: Tool {
    private var _editingItem: EllipseItem?
    var editingItem: (any ToolEditingItem)? {
        return _editingItem
    }

    func commit(to host: any ToolHost) {
        if let item = _editingItem.take() {
            host.commit(item: item)
        }
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        let item = EllipseItem(strokeColor: host.toolbarDataModel.strokeColor, strokeWidth: host.toolbarDataModel.strokeWidth)
        item.from = location.float2
        item.to = item.from
        _editingItem = item
        host.setNeedsDisplay()
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        commit(to: host)
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        if let _editingItem {
            _editingItem.isCircle = NSEvent.modifierFlags.contains(.shift)
            _editingItem.isCenterMode = NSEvent.modifierFlags.contains(.option)
            _editingItem.to = location.float2
            host.setNeedsDisplay()
        }
    }
}
