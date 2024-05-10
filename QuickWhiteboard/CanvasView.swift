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
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        viewController?.viewHasSetNewSize(newSize)
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
        if viewController?.pendingPath != nil {
            if event.type == .keyDown {
                NSSound.beep()
                return true
            }
        }
        return false
    }
    
}
