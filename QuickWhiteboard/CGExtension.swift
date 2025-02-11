//
//  CGExtension.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/30.
//

import Foundation
import CoreGraphics
import SwiftUI

let round_scale = 2.0

extension CGPoint {
    static func from(_ float2: Point2D) -> Self {
        .init(x: CGFloat(float2.x), y: CGFloat(float2.y))
    }

    var float2: Point2D {
        .init(x: Float(x), y: Float(y))
    }
    
    var rounded: Self {
        .init(x: CGFloat(floor(x * round_scale) / round_scale), y: CGFloat(floor(y * round_scale) / round_scale))
    }
}

extension CGSize {
    static func from(_ float2: Size2D) -> Self {
        .init(width: CGFloat(float2.x), height: CGFloat(float2.y))
    }

    var float2: Size2D {
        .init(x: Float(width), y: Float(height))
    }
    
    var rounded: Self {
        .init(width: CGFloat(floor(width * round_scale) / round_scale), height: CGFloat(floor(height * round_scale) / round_scale))
    }
}
