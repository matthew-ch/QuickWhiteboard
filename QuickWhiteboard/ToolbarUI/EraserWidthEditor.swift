//
//  EraserWidthEditor.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//

import SwiftUI

struct EraserWidthEditor: View {
    static let presetEraserWidth = [10, 20, 40, 80]
    static let formatter = {
        let formatter = NumberFormatter()
        formatter.maximumIntegerDigits = 2
        formatter.numberStyle = .none
        formatter.minimum = 1
        formatter.maximum = 99
        return formatter
    }()

    @Binding var width: CGFloat

    var body: some View {
        HStack {
            Text("Width")
                .font(.caption)
                .foregroundColor(.secondary)
            ForEach(Self.presetEraserWidth, id: \.self) { i in
                Button {
                    width = CGFloat(i)
                } label: {
                    Text("\(i)")
                }
            }
            Text("Customize")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Width", value: $width, formatter: Self.formatter)
                .frame(width: 32)
        }
    }
}
