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
    case rectangle
    case eraser
    case image
    
    var symbolName: String {
        switch self {
        case .freehand:
            "scribble"
        case .line:
            "line.diagonal"
        case .rectangle:
            "rectangle"
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
        case .rectangle:
            "R"
        case .eraser:
            "E"
        case .image:
            "I"
        }
    }
    
    var tooltip: String {
        switch self {
        case .freehand:
            "\(localizedString("Draw freehand")) (\(shortcutKey))"
        case .line:
            "\(localizedString("Draw line")) (\(shortcutKey))"
        case .rectangle:
            "\(localizedString("Draw rectangle")) (\(shortcutKey)"
        case .eraser:
            "\(localizedString("Erase drawings")) (\(shortcutKey))"
        case .image:
            "\(localizedString("Insert image")) (\(shortcutKey))"
        }
    }
}

class ImageItemProperty: ObservableObject {
    @Published var scale: CGFloat = 100.0
    @Published var rotation: CGFloat = 0.0
}

class ToolbarDataModel: ObservableObject {
    @Published var strokeWidth: CGFloat
    @Published var strokeColor: Color
    @Published var strokePresets: [StrokePreset]
    @Published var activeToolIdentifier: ToolIdentifier
    @Published var imageItemProperty: ImageItemProperty

    init(
        strokeWidth: CGFloat,
        strokeColor: Color,
        strokePresets: [StrokePreset] = [],
        activeToolIdentifier: ToolIdentifier = .freehand,
        imageItemProperty: ImageItemProperty = ImageItemProperty()
    ) {
        self.strokeWidth = strokeWidth
        self.strokeColor = strokeColor
        self.strokePresets = strokePresets
        self.activeToolIdentifier = activeToolIdentifier
        self.imageItemProperty = imageItemProperty
    }
}
