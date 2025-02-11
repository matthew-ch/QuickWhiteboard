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
    case ellipse
    case eraser
    case image
    case cursor

    var symbolName: String {
        switch self {
        case .freehand:
            "scribble"
        case .line:
            "line.diagonal"
        case .rectangle:
            "rectangle"
        case .ellipse:
            "oval"
        case .eraser:
            "xmark.circle"
        case .image:
            "photo"
        case .cursor:
            "cursorarrow.square"
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
        case .ellipse:
            "E"
        case .eraser:
            "X"
        case .image:
            "I"
        case .cursor:
            "A"
        }
    }

    var localizedKey: String {
        switch self {
        case .freehand:
            "Draw freehand"
        case .line:
            "Draw line"
        case .rectangle:
            "Draw rectangle"
        case .ellipse:
            "Draw ellipse"
        case .eraser:
            "Erase drawings"
        case .image:
            "Insert image"
        case .cursor:
            "Select & Move"
        }
    }

    var tooltip: String {
        "\(localizedString(localizedKey)) (\(shortcutKey))"
    }
}

class ImageItemProperty: ObservableObject {
    @Published var scale: CGFloat = 100.0
    @Published var rotation: CGFloat = 0.0
}

class ToolbarDataModel: ObservableObject {
    @Published var strokeWidth: CGFloat
    @Published var strokeColor: SIMD4<Float>
    @Published var strokePresets: [StrokePreset]
    @Published var activeToolIdentifier: ToolIdentifier
    @Published var imageItemProperty: ImageItemProperty

    init(
        strokeWidth: CGFloat,
        strokeColor: SIMD4<Float>,
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
