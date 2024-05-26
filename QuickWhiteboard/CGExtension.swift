//
//  CGExtension.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/30.
//

import Foundation

extension CGPoint {
    static func from(_ float2: SIMD2<Float>) -> Self {
        .init(x: CGFloat(float2.x), y: CGFloat(float2.y))
    }

    var float2: SIMD2<Float> {
        .init(x: Float(x), y: Float(y))
    }
    
    var rounded: Self {
        .init(x: CGFloat(floor(x * 2.0) / 2.0), y: CGFloat(floor(y * 2.0) / 2.0))
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
        .init(width: CGFloat(floor(width * 2.0) / 2.0), height: CGFloat(floor(height * 2.0) / 2.0))
    }
}
