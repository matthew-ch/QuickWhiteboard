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

class FreehandTool: Tool {
    fileprivate var _editingItem: DrawingItem? = nil
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
        let item = DrawingItem(color:  NSColor(delegate.toolbarDataModel.color).usingColorSpace(.sRGB)!.cgColor, strokeWidth: delegate.toolbarDataModel.strokeWidth)
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
    
    func setCursor() {
        NSCursor.crosshair.set()
    }
}

class LineTool: FreehandTool {
    static let dirXs = SIMD8<Float>(arrayLiteral: 0.0, halfOfSqrt2, 1.0, halfOfSqrt2, 0.0, -halfOfSqrt2, -1.0, -halfOfSqrt2)
    static let dirYs = SIMD8<Float>(arrayLiteral: 1.0, halfOfSqrt2, 0.0, -halfOfSqrt2, -1.0, -halfOfSqrt2, 0.0, halfOfSqrt2)
    override func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let _editingItem {
            guard _editingItem.points.count > 0 else {
                super.mouseDragged(with: event, location: location)
                return
            }
            let targetLocation: CGPoint
            while _editingItem.points.count > 1 {
                _editingItem.popLastSample()
            }
            if !NSEvent.modifierFlags.contains(.shift) {
                targetLocation = location
            } else {
                let origin = _editingItem.points[0].location
                let v = location.float2 - origin
                let dots = Self.dirXs * v.x + Self.dirYs * v.y
                var maxIndex = 0
                var maxValue = dots[0]
                for index in 1..<8 {
                    if dots[index] > maxValue {
                        maxValue = dots[index]
                        maxIndex = index
                    }
                }

                let u = SIMD2<Float>(Self.dirXs[maxIndex], Self.dirYs[maxIndex]) * maxValue
                targetLocation = CGPoint.from(origin + u)
            }
            if targetLocation.float2 != _editingItem.points[0].location {
                _editingItem.addPointSample(location: targetLocation)
                delegate.setNeedsDisplay()
            }
        }
    }
}

class RectangleTool: FreehandTool {
    override func mouseDragged(with event: NSEvent, location: CGPoint) {
        if let _editingItem {
            guard _editingItem.points.count > 0 else {
                super.mouseDragged(with: event, location: location)
                return
            }
            while _editingItem.points.count > 1 {
                _editingItem.popLastSample()
            }
            let origin = CGPoint.from(_editingItem.points[0].location)
            let targetLocation: CGPoint
            if NSEvent.modifierFlags.contains(.shift) {
                let diffX = location.x - origin.x
                let diffY = location.y - origin.y
                let length = min(abs(diffX), abs(diffY));
                targetLocation = .init(x: origin.x + (diffX >= 0 ? length : -length), y: origin.y + (diffY >= 0 ? length : -length))
            } else {
                targetLocation = location
            }
            if origin == targetLocation {
                return
            }
            if origin.x != targetLocation.x && origin.y != targetLocation.y {
                _editingItem.addPointSample(location: .init(x: origin.x, y: targetLocation.y))
                _editingItem.addPointSample(location: targetLocation)
                _editingItem.addPointSample(location: .init(x: targetLocation.x, y: origin.y))
                _editingItem.addPointSample(location: origin)
            } else {
                _editingItem.addPointSample(location: targetLocation)
            }
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
            guard let drawingItem = renderItem as? DrawingItem, !drawingItem.points.isEmpty else {
                continue
            }
            var previousPoint = drawingItem.points[0]
            let distanceTest = drawingItem.strokeWidth / 2.0 + Float(eraserRadius)
            for point in drawingItem.points {
                if distanceFromPointToLineSegment(point: location.float2, segmentPoints: previousPoint.location, point.location) <= distanceTest {
                    return renderItem
                }
                previousPoint = point
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
