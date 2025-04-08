//
//  ColorCircle.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//
import SwiftUI

struct ColorCircle: View {
    let color: SIMD4<Float>
    var size: CGFloat = 16.0

    var body: some View {
        if color.w != 1.0 {
            Circle()
                .fill(makeGradient(color: color, varying: \.w))
                .frame(width: size, height: size)
        } else {
            Circle()
                .fill(Color.from(simd4: opaqueColor(color)))
                .frame(width: size, height: size)
        }
    }
}
