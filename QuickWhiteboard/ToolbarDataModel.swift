//
//  ToolbarDataModel.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/6/9.
//

import Foundation
import SwiftUI

enum ToolIdentifier: Equatable, Hashable, Identifiable, CaseIterable {
    var id: Self {
        self
    }
    
    case freehand
    case line
    case eraser
    case image
    
    var symbolName: String {
        switch self {
        case .freehand:
            "scribble"
        case .line:
            "line.diagonal"
        case .eraser:
            "xmark.circle"
        case .image:
            "photo"
        }
    }
    
    var shortcutKey: String {
        switch self {
        case .freehand:
            "F"
        case .line:
            "S"
        case .eraser:
            "E"
        case .image:
            "I"
        }
    }
    
    var tooltip: String {
        switch self {
        case .freehand:
            "Draw freehand (\(shortcutKey))"
        case .line:
            "Draw line (\(shortcutKey))"
        case .eraser:
            "Erase drawings (\(shortcutKey))"
        case .image:
            "Insert image (\(shortcutKey))"
        }
    }
}

class ImageItemProperty: ObservableObject {
    @Published var scale: CGFloat = 100.0
    @Published var rotation: CGFloat = 0.0
}

class ToolbarDataModel: ObservableObject {
    @Published var strokeWidth: CGFloat
    @Published var color: Color
    @Published var activeToolIdentifier: ToolIdentifier
    @Published var imageItemProperty: ImageItemProperty

    init(
        strokeWidth: CGFloat,
        color: Color,
        activeToolIdentifier: ToolIdentifier = .freehand,
        imageItemProperty: ImageItemProperty = ImageItemProperty()
    ) {
        self.strokeWidth = strokeWidth
        self.color = color
        self.activeToolIdentifier = activeToolIdentifier
        self.imageItemProperty = imageItemProperty
    }
}
