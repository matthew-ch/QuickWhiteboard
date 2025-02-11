//
//  MovedItems.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/11.
//

import Foundation

final class MovedItems: ToolEditingItem {
    let items: [any RenderItem]
    private(set) var offset: CGPoint = .zero
    private(set) var moved = false

    init(items: [any RenderItem]) {
        self.items = items
    }

    func update(dx: CGFloat, dy: CGFloat) {
        moved = true
        offset.x += dx
        offset.y += dy
        for item in items {
            item.globalPosition.x += dx
            item.globalPosition.y += dy
        }
    }

    func apply() {
        guard !moved else {
            return
        }
        for item in items {
            item.globalPosition.x += offset.x
            item.globalPosition.y += offset.y
        }
        moved = true
    }

    func revert() {
        guard moved else {
            return
        }
        for item in items {
            item.globalPosition.x -= offset.x
            item.globalPosition.y -= offset.y
        }
        moved = false
    }
}
