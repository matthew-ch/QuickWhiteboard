//
//  Tools.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/6/9.
//

import Foundation
import AppKit
import Combine

protocol ToolDelegate: AnyObject {
    func setNeedsDisplay() -> Void
    func commit(item: any RenderItem) -> Void
    var toolbarDataModel: ToolbarDataModel { get }
    func setDefaultTool() -> Void
}

protocol Tool: AnyObject {
    init(delegate: any ToolDelegate)
    var delegate: any ToolDelegate { get }
    var editingItem: (any RenderItem)? { get }
    func commit() -> Void
    func mouseDown(with event: NSEvent, location: CGPoint) -> Void
    func mouseUp(with event: NSEvent, location: CGPoint) -> Void
    func mouseDragged(with event: NSEvent, location: CGPoint) -> Void
    func setCursor() -> Void
}

class FreehandTool: Tool {
    fileprivate var _editingItem: DrawingItem? = nil
    var editingItem: (any RenderItem)? {
        _editingItem
    }
    unowned let delegate: any ToolDelegate
    
    required init(delegate: any ToolDelegate) {
        self.delegate = delegate
    }

    func commit() {
        if let item = _editingItem.take() {
            delegate.commit(item: item)
        }
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint) {
        let item = DrawingItem(color:  NSColor(delegate.toolbarDataModel.color).usingColorSpace(.sRGB)!.cgColor, strokeWidth: delegate.toolbarDataModel.strokeWidth)
        item.addPointSample(location: location)
        _editingItem = item
        delegate.setNeedsDisplay()
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint) {
        commit()
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let _editingItem {
            _editingItem.addPointSample(location: location)
            delegate.setNeedsDisplay()
        }
    }
    
    func setCursor() {
        NSCursor.crosshair.set()
    }
}

class LineTool: FreehandTool {
    override func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let _editingItem {
            if _editingItem.points.count > 1 {
                _editingItem.popLastSample()
            }
            _editingItem.addPointSample(location: location)
            delegate.setNeedsDisplay()
        }
    }
}

class ImageTool: Tool {
    private var _editingItem: ImageItem? = nil
    required init(delegate: any ToolDelegate) {
        self.delegate = delegate
    }
    
    unowned let delegate: any ToolDelegate
    private var imageItemPropertyChange: AnyCancellable?

    var editingItem: (any RenderItem)? {
        _editingItem
    }
    
    func setImageItem(item: ImageItem) {
        _editingItem = item
        let imageItemProperty = ImageItemProperty()
        imageItemPropertyChange = imageItemProperty.objectWillChange.sink { [weak delegate] _ in
            DispatchQueue.main.async {
                item.scale = Float(imageItemProperty.scale / 100.0)
                item.rotation = Float(imageItemProperty.rotation / 180 * CGFloat.pi)
                delegate?.setNeedsDisplay()
            }
        }
        delegate.toolbarDataModel.imageItemProperty = imageItemProperty
        delegate.setNeedsDisplay()
    }
    
    func commit() {
        if let item = _editingItem.take() {
            delegate.commit(item: item)
            delegate.setDefaultTool()
        }
        imageItemPropertyChange = nil
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint) {
        // emtpy
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint) {
        // empty
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let _editingItem {
            _editingItem.center += SIMD2<Float>(x: Float(event.deltaX), y: Float(-event.deltaY))
            delegate.setNeedsDisplay()
        }
    }
    
    func setCursor() {
        NSCursor(image: NSImage(systemSymbolName: "arrow.up.and.down.and.arrow.left.and.right", accessibilityDescription: nil)!, hotSpot: .zero).set()
    }
    
    
}
