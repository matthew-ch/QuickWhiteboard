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
    case grid

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
        case .grid:
            "grid"
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
        case .grid:
            "G"
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
        case .grid:
            "Grid"
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
    @Published var eraserWidth: CGFloat
    @Published var activeToolIdentifier: ToolIdentifier
    @Published var imageItemProperty: ImageItemProperty
    @Published var isGridVisible: Bool
    @Published var gridColor: SIMD4<Float>
    @Published var gridSpacing: CGFloat

    init(
        strokeWidth: CGFloat,
        strokeColor: SIMD4<Float>,
        strokePresets: [StrokePreset] = [],
        eraserWidth: CGFloat = 10.0,
        activeToolIdentifier: ToolIdentifier = .freehand,
        imageItemProperty: ImageItemProperty = ImageItemProperty(),
        isGridVisible: Bool = false,
        gridColor: SIMD4<Float> = SIMD4<Float>(x: 0.75, y: 0.75, z: 0.75, w: 1.0),
        gridSpacing: CGFloat = 20.0
    ) {
        self.strokeWidth = strokeWidth
        self.strokeColor = strokeColor
        self.eraserWidth = eraserWidth
        self.strokePresets = strokePresets
        self.activeToolIdentifier = activeToolIdentifier
        self.imageItemProperty = imageItemProperty
        self.isGridVisible = isGridVisible
        self.gridColor = gridColor
        self.gridSpacing = gridSpacing
    }
}
