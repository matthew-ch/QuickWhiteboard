//
//  Helpers.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//

import Foundation
import SwiftUI

extension Color {
    static func from(simd4: SIMD4<Float>) -> Self {
        .init(red: Double(simd4.x), green: Double(simd4.y), blue: Double(simd4.z), opacity: Double(simd4.w))
    }
}

func makeGradient<VaryingKeyPath: WritableKeyPath<SIMD4<Float>, Float>>(color: SIMD4<Float>, varying keyPath: VaryingKeyPath) -> LinearGradient {
    var start = color
    start[keyPath: keyPath] = 0.0
    var end = color
    end[keyPath: keyPath] = 1.0
    return LinearGradient(colors: [Color.from(simd4: start), Color.from(simd4: end)], startPoint: .init(x: 0, y: 0.5), endPoint: .init(x: 1.0, y: 0.5))
}

func opaqueColor(_ color: SIMD4<Float>) -> SIMD4<Float> {
    var color = color
    color.w = 1.0
    return color
}
