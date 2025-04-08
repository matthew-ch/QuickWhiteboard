//
//  StrokeWidthEditor.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//
import SwiftUI

struct StrokeWidthEditor: View {
    static let presetStrokeWidth = [1,2,4,8,16,32]
    static let formatter = {
        let formatter = NumberFormatter()
        formatter.maximumIntegerDigits = 2
        formatter.numberStyle = .none
        formatter.minimum = 1
        formatter.maximum = 99
        return formatter
    }()

    @Binding var width: CGFloat
    @State private var isShowingPopover = false

    var body: some View {
        Button {
            isShowingPopover = true
        } label: {
            Text("\(Self.formatter.string(from: width as NSNumber)!)")
                .frame(minWidth: 16.0)
        }
        .help("Width")
        .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
            VStack(spacing: 8.0) {
                HStack {
                    ForEach(Self.presetStrokeWidth, id: \.self) { i in
                        Button {
                            width = CGFloat(i)
                            isShowingPopover = false
                        } label: {
                            Text("\(i)")
                        }
                    }
                }
                HStack {
                    Text("Customize")
                        .font(.caption)
                    TextField("Width", value: $width, formatter: Self.formatter)
                        .frame(width: 32)
                }
            }
            .padding(.all, 12.0)
        }
    }
}
