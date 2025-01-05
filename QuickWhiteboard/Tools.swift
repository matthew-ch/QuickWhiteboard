//
//  Tools.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/6/9.
//

import Foundation
import AppKit
import Combine

@MainActor
protocol ToolEditingItem: AnyObject {}

@MainActor
protocol ToolDelegate: AnyObject {
    func setNeedsDisplay() -> Void
    func commit(item: any ToolEditingItem) -> Void
    var toolbarDataModel: ToolbarDataModel { get }
    func setDefaultTool() -> Void
    var renderItems: [any RenderItem] { get }
}

@MainActor
protocol Tool: AnyObject {
    init(delegate: any ToolDelegate)
    var delegate: any ToolDelegate { get }
    var editingItem: (any ToolEditingItem)? { get }
    func commit() -> Void
    func mouseDown(with event: NSEvent, location: CGPoint) -> Void
    func mouseUp(with event: NSEvent, location: CGPoint) -> Void
    func mouseDragged(with event: NSEvent, location: CGPoint) -> Void
    func setCursor() -> Void
}

extension Tool {
    func setCursor() {
        NSCursor.crosshair.set()
    }
}

class FreehandTool: Tool {
    private var _editingItem: FreehandItem?
    var editingItem: (any ToolEditingItem)? {
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
        let item = FreehandItem(strokeColor: delegate.toolbarDataModel.strokeColor, strokeWidth: delegate.toolbarDataModel.strokeWidth)
        item.addPointSample(location: location)
        _editingItem = item
        delegate.setNeedsDisplay()
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint) {
        commit()
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let _editingItem, location.float2 != _editingItem.points.last?.location {
            _editingItem.addPointSample(location: location)
            delegate.setNeedsDisplay()
        }
    }
}

class LineTool: Tool {
    private var _editingItem: LineItem?
    var editingItem: (any ToolEditingItem)? {
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
        let item = LineItem(strokeColor: delegate.toolbarDataModel.strokeColor, strokeWidth: delegate.toolbarDataModel.strokeWidth)
        item.from = location.float2
        item.to = item.from
        _editingItem = item
        delegate.setNeedsDisplay()
    }

    func mouseUp(with event: NSEvent, location: CGPoint) {
        commit()
    }

    func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let _editingItem {
            _editingItem.isCenterMode = NSEvent.modifierFlags.contains(.option)
            _editingItem.isAligning = NSEvent.modifierFlags.contains(.shift)
            _editingItem.to = location.float2
            delegate.setNeedsDisplay()
        }
    }
}

class RectangleTool: Tool {
    private var _editingItem: RectangleItem?
    var editingItem: (any ToolEditingItem)? {
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
        let item = RectangleItem(strokeColor: delegate.toolbarDataModel.strokeColor, strokeWidth: delegate.toolbarDataModel.strokeWidth)
        item.from = location.float2
        item.to = item.from
        _editingItem = item
        delegate.setNeedsDisplay()
    }

    func mouseUp(with event: NSEvent, location: CGPoint) {
        commit()
    }

    func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let _editingItem {
            _editingItem.isSquare = NSEvent.modifierFlags.contains(.shift)
            _editingItem.isCenterMode = NSEvent.modifierFlags.contains(.option)
            _editingItem.to = location.float2
            delegate.setNeedsDisplay()
        }
    }
}

class EllipseTool: Tool {
    private var _editingItem: EllipseItem?
    var editingItem: (any ToolEditingItem)? {
        return _editingItem
    }

    unowned var delegate: any ToolDelegate
    required init(delegate: any ToolDelegate) {
        self.delegate = delegate
    }
    
    func commit() {
        if let item = _editingItem.take() {
            delegate.commit(item: item)
        }
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint) {
        let item = EllipseItem(strokeColor: delegate.toolbarDataModel.strokeColor, strokeWidth: delegate.toolbarDataModel.strokeWidth)
        item.from = location.float2
        item.to = item.from
        _editingItem = item
        delegate.setNeedsDisplay()
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint) {
        commit()
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let _editingItem {
            _editingItem.isCircle = NSEvent.modifierFlags.contains(.shift)
            _editingItem.isCenterMode = NSEvent.modifierFlags.contains(.option)
            _editingItem.to = location.float2
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

    var editingItem: (any ToolEditingItem)? {
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
        let image = NSImage(systemSymbolName: "arrow.up.and.down.and.arrow.left.and.right", accessibilityDescription: nil)!
        NSCursor(image: image, hotSpot: CGPoint.from(image.size.float2 / 2.0)).set()
    }
    
    
}

let eraserRadius = 5.0

class EraserTool: Tool {
    private var _editingItem: ErasedItems? = nil
    
    required init(delegate: any ToolDelegate) {
        self.delegate = delegate
    }
    
    unowned let delegate: any ToolDelegate
    
    var editingItem: (any ToolEditingItem)? {
        _editingItem
    }
    
    func commit() {
        if let item = _editingItem.take(), !item.selected.isEmpty {
            delegate.commit(item: item)
        }
    }
    
    private func queryIntersectedItem(location: CGPoint) -> RenderItem? {
        for renderItem in delegate.renderItems.reversed() {
            if renderItem.hidden || !renderItem.boundingRect.insetBy(dx: -eraserRadius, dy: -eraserRadius).contains(location) {
                continue
            }
            guard let drawingItem = renderItem as? DrawingItem else {
                continue
            }
            let distanceTest = drawingItem.strokeWidth / 2.0 + Float(eraserRadius)
            if drawingItem.distanceToPath(from: location) <= distanceTest {
                return renderItem
            }
        }
        return nil
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint) {
        let item = ErasedItems()
        if let renderItem = queryIntersectedItem(location: location) {
            renderItem.hidden = true
            item.selected.append(renderItem)
            delegate.setNeedsDisplay()
        }
        _editingItem = item
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint) {
        commit()
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let item = _editingItem,
            let renderItem = queryIntersectedItem(location: location) {
            renderItem.hidden = true
            item.selected.append(renderItem)
            delegate.setNeedsDisplay()
        }
    }
    
    func setCursor() {
        let image = NSImage(systemSymbolName: ToolIdentifier.eraser.symbolName, accessibilityDescription: nil)!
        NSCursor(image: image, hotSpot: CGPoint.from(image.size.float2 / 2.0)).set()
    }

}
