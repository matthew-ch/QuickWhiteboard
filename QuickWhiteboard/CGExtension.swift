//
//  CGExtension.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/30.
//

import Foundation
import CoreGraphics
import SwiftUI

let round_scale: CGFloat = 2.0

extension CGPoint {
    static func from(_ float2: Point2D) -> Self {
        .init(x: CGFloat(float2.x), y: CGFloat(float2.y))
    }

    var float2: Point2D {
        .init(x: Float(x), y: Float(y))
    }
    
    var alignedToSubpixel: Self {
        .init(x: floor(x * round_scale) / round_scale, y: floor(y * round_scale) / round_scale)
    }

    var rounded: Self {
        .init(x: round(x), y: round(y))
    }
}

extension CGSize {
    static func from(_ float2: Size2D) -> Self {
        .init(width: CGFloat(float2.x), height: CGFloat(float2.y))
    }

    var float2: Size2D {
        .init(x: Float(width), y: Float(height))
    }
    
    var alignedToSubpixel: Self {
        .init(width: CGFloat(floor(width * round_scale) / round_scale), height: CGFloat(floor(height * round_scale) / round_scale))
    }
}
