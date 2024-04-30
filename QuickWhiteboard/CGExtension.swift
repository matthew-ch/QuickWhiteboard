//
//  CGExtension.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/30.
//

import Foundation

extension CGPoint {
    var float2: SIMD2<Float> {
        .init(x: Float(x), y: Float(y))
    }
}

extension CGSize {
    var float2: SIMD2<Float> {
        .init(x: Float(width), y: Float(height))
    }
}
