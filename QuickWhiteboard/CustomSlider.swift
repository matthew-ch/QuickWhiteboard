//
//  CustomSlider.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/1/2.
//

import SwiftUI

struct CustomSlider<BackgroundFill: ShapeStyle, Value: BinaryFloatingPoint>: View {

    @Binding var value: Value

    let fillBackground: () -> BackgroundFill

    var body: some View {
        GeometryReader { proxy in
            ZStack() {
                RoundedRectangle(cornerRadius: 2.0)
                    .fill(fillBackground())
                RoundedRectangle(cornerRadius: 1.0)
                    .fill(Color.white)
                    .shadow(radius: 1.0)
                    .frame(width: 10.0)
                    .position(x: Double(value) * proxy.size.width, y: proxy.size.height / 2.0)
            }
            .gesture(
                DragGesture(minimumDistance: 1.0)
                    .onChanged { v in
                        let x = min(max(v.location.x, 0.0), proxy.size.width)
                        value = Value(x / proxy.size.width)
                    }
            )
        }
    }
}

private struct SliderPreviewWrapper: View {
    @State var value = 0.25

    var body: some View {
        CustomSlider(value: $value, fillBackground: {
            Color.green
        })
        .frame(width: 200, height: 24)
        .padding(20)
    }
}

#Preview {
    SliderPreviewWrapper()
}
