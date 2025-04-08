//
//  StrokeColorEditor.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//

import SwiftUI

let presetColors: [SIMD4<Float>] = [
    .init(x: 1.0, y: 0.15, z: 0.0, w: 1.0),
    .init(x: 0.0, y: 0.98, z: 0.0, w: 1.0),
    .init(x: 0.02, y: 0.2, z: 1.0, w: 1.0),

    .init(x: 0.0, y: 0.99, z: 1.0, w: 1.0),
    .init(x: 1.0, y: 0.25, z: 1.0, w: 1.0),
    .init(x: 0.99, y: 0.98, z: 0.0, w: 1.0),

    .init(x: 0.0, y: 0.0, z: 0.0, w: 1.0),
    .init(x: 0.25, y: 0.25, z: 0.25, w: 1.0),
    .init(x: 0.5, y: 0.5, z: 0.5, w: 1.0),
    .init(x: 0.75, y: 0.75, z: 0.75, w: 1.0),
    .init(x: 1.0, y: 1.0, z: 1.0, w: 1.0),
]

struct StrokeColorEditor: View {

    @Binding var color: SIMD4<Float>
    @State private var isShowingPopover = false

    var body: some View {
        Button {
            isShowingPopover = true
        } label: {
            ColorCircle(color: color)
        }
        .help("Color")
        .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
            VStack {
                HStack {
                    ForEach(0..<presetColors.count, id: \.self) { i in
                        Button {
                            color = presetColors[i]
                        } label: {
                            ColorCircle(color: presetColors[i])
                        }
                    }
                }
                .buttonStyle(.plain)

                Text("Customize")
                    .font(.caption)
                    .padding(.top, 8.0)

                VStack {
                    CustomSlider(value: $color.x) {
                        makeGradient(color: opaqueColor(color), varying: \.x)
                    }
                    .frame(height: 24.0)
                    CustomSlider(value: $color.y) {
                        makeGradient(color: opaqueColor(color), varying: \.y)
                    }
                    .frame(height: 24.0)
                    CustomSlider(value: $color.z) {
                        makeGradient(color: opaqueColor(color), varying: \.z)
                    }
                    .frame(height: 24.0)
                    CustomSlider(value: $color.w) {
                        makeGradient(color: color, varying: \.w)
                    }
                    .frame(height: 24.0)
                    .background(
                        Checkerboard(cellLength: 8.0)
                            .clipShape(RoundedRectangle(cornerRadius: 2.0))
                    )
                }
                .frame(width: 256.0)
                .padding(.horizontal, 8.0)

            }
            .padding(.all, 12.0)
        }
    }
}
