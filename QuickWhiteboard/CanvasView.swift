//
//  CanvasView.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/30.
//

import Cocoa
import MetalKit

class CanvasView: MTKView {
    
    var viewController: ViewController? {
        delegate as? ViewController
    }
    
    override var mouseDownCanMoveWindow: Bool {
        false
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
    
    override func cursorUpdate(with event: NSEvent) {
        viewController?.canvasSetCursor(with: event)
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        viewController?.viewHasSetNewSize(newSize)
    }
    
    override func scrollWheel(with event: NSEvent) {
        viewController?.canvasViewScrollWheel(with: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        viewController?.canvasViewMouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        viewController?.canvasViewMouseUp(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        viewController?.canvasViewMouseDragged(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        viewController?.canvasRightMouseDown(with: event)
    }

    override func rightMouseDragged(with event: NSEvent) {
        viewController?.canvasRightMouseDragged(with: event)
    }

    override func rightMouseUp(with event: NSEvent) {
        viewController?.canvasRightMouseUp(with: event)
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if let viewController = viewController {
            return viewController.draggingEntered(sender)
        }
        return []
    }
    
    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        if let viewController = viewController {
            return viewController.performDragOperation(sender)
        }
        return false
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if viewController?.isEditing ?? false {
            if event.type == .keyDown {
                NSSound.beep()
                return true
            }
        }
        return false
    }
    
    override func keyDown(with event: NSEvent) {
        viewController?.keyDown(with: event)
    }
    
}
