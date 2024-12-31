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
    static func from(_ float2: SIMD2<Float>) -> Self {
        .init(x: CGFloat(float2.x), y: CGFloat(float2.y))
    }

    var float2: SIMD2<Float> {
        .init(x: Float(x), y: Float(y))
    }
    
    var rounded: Self {
        .init(x: CGFloat(floor(x * round_scale) / round_scale), y: CGFloat(floor(y * round_scale) / round_scale))
    }
}

extension CGSize {
    static func from(_ float2: SIMD2<Float>) -> Self {
        .init(width: CGFloat(float2.x), height: CGFloat(float2.y))
    }

    var float2: SIMD2<Float> {
        .init(x: Float(width), y: Float(height))
    }
    
    var rounded: Self {
        .init(width: CGFloat(floor(width * round_scale) / round_scale), height: CGFloat(floor(height * round_scale) / round_scale))
    }
}

extension CGColor {
    var float4: SIMD4<Float> {
        assert(self.colorSpace?.model == .rgb && self.numberOfComponents >= 3)
        let components = self.components!
        return .init(Float(components[0]), Float(components[1]), Float(components[2]), Float(self.numberOfComponents == 3 ? 1.0 : components[3]))
    }

    static func from(_ color: Color) -> CGColor {
        NSColor(color).usingColorSpace(.sRGB)!.cgColor
    }
}
