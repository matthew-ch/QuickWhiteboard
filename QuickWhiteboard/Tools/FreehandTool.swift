//
//  FreehandTool.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/10.
//

import Foundation
import AppKit

final class FreehandTool: Tool {
    private var _editingItem: FreehandItem?
    var editingItem: (any ToolEditingItem)? {
        _editingItem
    }

    func commit(to host: any ToolHost) {
        if let item = _editingItem.take() {
            host.commit(item: item)
        }
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        let item = FreehandItem(strokeColor: host.toolbarDataModel.strokeColor, strokeWidth: host.toolbarDataModel.strokeWidth)
        item.addPointSample(location: location, pressure: event.pressure)
        _editingItem = item
        host.setNeedsDisplay()
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        commit(to: host)
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        if let _editingItem, location.float2 != _editingItem.points.last?.location {
            _editingItem.addPointSample(location: location, pressure: event.pressure)
            host.setNeedsDisplay()
        }
    }
}
