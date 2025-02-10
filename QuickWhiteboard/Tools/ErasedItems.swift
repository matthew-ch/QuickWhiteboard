//
//  ErasedItems.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/3.
//

final class ErasedItems: ToolEditingItem {
    var selected: [any RenderItem] = []
    
    func erase() {
        for item in selected {
            item.hidden = true
        }
    }
    
    func restore() {
        for item in selected {
            item.hidden = false
        }
    }
}
