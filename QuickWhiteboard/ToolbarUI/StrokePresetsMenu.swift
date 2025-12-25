//
//  StrokePresetsMenu.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//

import SwiftUI

struct StrokePresetsMenu: View {

    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?
    @State private var isShowingPopover = false

    var body: some View {
        HStack {
            Button {
                self.isShowingPopover = true
            } label: {
                Image(systemName: "pencil.tip.crop.circle")
            }
            .help("Presets")
            .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
                VStack(spacing: 4.0) {
                    Button {
                        delegate?.addStrokePreset()
                        isShowingPopover = false
                    } label: {
                        HStack(alignment: .center, spacing: 2.0) {
                            Text("\(Int(dataModel.strokeWidth))")
                                .frame(width: 24.0)
                            ColorCircle(color: dataModel.strokeColor)
                            Image(systemName: "plus.circle")
                                .padding(.horizontal, 4.0)
                        }
                        .padding(.horizontal, 8.0)
                    }
                    .buttonStyle(.borderless)

                    if dataModel.strokePresets.count > 0 {
                        Divider()
                    }

                    ForEach(dataModel.strokePresets) { stroke in
                        Button {
                            dataModel.strokeWidth = stroke.width
                            dataModel.strokeColor = stroke.color
                            isShowingPopover = false
                        } label: {
                            HStack(alignment: .center, spacing: 2.0) {
                                Text("\(Int(stroke.width))")
                                    .frame(width: 24.0)
                                ColorCircle(color: stroke.color)
                                Button {
                                    delegate?.removeStrokePreset(preset: stroke)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.borderless)
                                .padding(.horizontal, 4.0)
                            }
                            .padding(.horizontal, 8.0)
                        }
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 6.0)
            }

            HStack {
                ForEach(dataModel.strokePresets) { stroke in
                    Button {
                        dataModel.strokeWidth = stroke.width
                        dataModel.strokeColor = stroke.color
                    } label: {
                        StrokeColorSizeWidget(strokeColor: stroke.color, strokeWidth: stroke.width)
                    }

                }
                Spacer(minLength: 0)
            }
            .buttonStyle(.plain)
        }
    }
}

fileprivate struct StrokeColorSizeWidget: View {

    let strokeColor: SIMD4<Float>
    let strokeWidth: CGFloat

    @ViewBuilder
    var colorShape: some View {
        if strokeColor.w != 1.0 {
            Rectangle()
                .fill(makeGradient(color: strokeColor, varying: \.w))
        } else {
            Rectangle()
                .fill(Color.from(simd4: opaqueColor(strokeColor)))
        }
    }

    var body: some View {
        colorShape
            .frame(width: 20, height: 20)
            .overlay(
                HStack {
                    Spacer(minLength: 0)
                    Text("\(Int(strokeWidth))")
                        .font(.caption2)
                    Spacer(minLength: 0)
                }
                    .frame(width: 22)
                    .background(Rectangle().colorInvert())
                    .overlay(
                        Rectangle().frame(height: 1),
                        alignment: .top
                    )
                    .opacity(0.75),
                alignment: .bottom
            )
            .clipShape(Circle())

    }
}

#Preview {
    let strokePresets = [
        StrokePreset(width: 2.0, color: presetColors[0]),
        StrokePreset(width: 4.0, color: presetColors[1]),
    ]

    StrokePresetsMenu(dataModel: ToolbarDataModel(strokeWidth: 4.0, strokeColor: presetColors[0], strokePresets: strokePresets), delegate: nil)
        .frame(width: 400, height: 40)

    StrokeColorSizeWidget(strokeColor: presetColors[1], strokeWidth: 88)
}
