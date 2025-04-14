//
//  NoOpTool.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/14.
//

import Foundation
import AppKit

final class NoOpTool: Tool {
    var editingItem: (any ToolEditingItem)?
    
    func commit(to host: any ToolHost) {
        host.setDefaultTool()
    }
    
    func mouseDown(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        // do nothing
    }
    
    func mouseUp(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        // do nothing
    }
    
    func mouseDragged(with event: NSEvent, location: CGPoint, host: any ToolHost) {
        // do nothing
    }

    func setCursor(host: any ToolHost) {
        NSCursor.operationNotAllowed.set()
    }

}
