//
//  ImageTool.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/10.
//

import Foundation
import AppKit
import Combine

final class ImageTool: Tool {
    private var _editingItem: ImageItem? = nil
    private var imageItemPropertyChange: AnyCancellable?

    var editingItem: (any ToolEditingItem)? {
        _editingItem
    }
    
    func setImageItem(item: ImageItem, host: any ToolHost) {
        _editingItem = item
        let imageItemProperty = ImageItemProperty()
        imageItemPropertyChange = imageItemProperty.objectWillChange.sink { [weak host] _ in
            DispatchQueue.main.async {
                item.scale = Float(imageItemProperty.scale / 100.0)
                item.rotation = Float(imageItemProperty.rotation / 180 * CGFloat.pi)
                host?.setNeedsDisplay()
            }
        }
        host.toolbarDataModel.imageItemProperty = imageItemProperty
        host.setNeedsDisplay()
    }
    
    func commit(to host: any ToolHost) {
        if let item = _editingItem.take() {
            host.commit(item: item)
            host.setDefaultTool()
        }
        imageItemPropertyChange = nil
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        // emtpy
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        // empty
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        if let _editingItem {
            _editingItem.globalPosition.x += event.deltaX
            _editingItem.globalPosition.y += -event.deltaY
            host.setNeedsDisplay()
        }
    }
    
    func setCursor() {
        let image = NSImage(systemSymbolName: "arrow.up.and.down.and.arrow.left.and.right", accessibilityDescription: nil)!
        NSCursor(image: image, hotSpot: CGPoint.from(image.size.float2 / 2.0)).set()
    }
    
    
}
