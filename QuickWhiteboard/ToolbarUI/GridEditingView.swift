//
//  GridEditingView.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/14.
//

import SwiftUI

struct GridEditingView: View {

    @Binding var isGridVisible: Bool

    @Binding var gridColor: SIMD4<Float>

    @Binding var spacing: CGFloat

    var body: some View {
        Text("Grid")
            .font(.caption)
            .foregroundColor(.secondary)

        Toggle(isOn: $isGridVisible, label: {})

        if isGridVisible {
            WidthEditor(width: $spacing, presets: [20, 32, 40, 64, 80], minimum: 10, maximum: 100, titleKey: "Spacing")

            ColorEditor(color: $gridColor, editsOpacity: false)
        }
    }
}

#Preview {
    HStack {
        GridEditingView(isGridVisible: Binding.constant(true), gridColor: Binding.constant(.zero), spacing: Binding.constant(20.0))
    }
}
