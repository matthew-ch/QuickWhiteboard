//
//  ToolbarControls.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/5/25.
//

import SwiftUI

extension Color {
    static func from(simd4: SIMD4<Float>) -> Self {
        .init(red: Double(simd4.x), green: Double(simd4.y), blue: Double(simd4.z), opacity: Double(simd4.w))
    }
}

private let presetColors: [SIMD4<Float>] = [
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

@MainActor
protocol ToolbarDelegate: AnyObject {
    func toggleDebug() -> Void
    func exportCanvas(_ sender: NSButton) -> Void
    func addStrokePreset() -> Void
    func removeStrokePreset(preset: StrokePreset) -> Void
    func onClickTool(identifier: ToolIdentifier) -> Void
    func commitActiveTool() -> Void
}

struct ExportButton: NSViewRepresentable {

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(
            image: NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)!,
            target: context.coordinator,
            action: #selector(ViewController.exportCanvas(_:))
        )
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return button
    }
    
    func updateNSView(_ nsView: NSButton, context: Context) {
    }
    
    typealias NSViewType = NSButton
}

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

struct ColorCircle: View {
    let color: SIMD4<Float>

    var body: some View {
        if color.w != 1.0 {
            Circle()
                .fill(makeGradient(color: color, varying: \.w))
                .frame(width: 16.0, height: 16.0)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.from(simd4: opaqueColor(color)))
                .frame(width: 16.0, height: 16.0)
        }
    }
}

private func makeGradient<VaryingKeyPath: WritableKeyPath<SIMD4<Float>, Float>>(color: SIMD4<Float>, varying keyPath: VaryingKeyPath) -> LinearGradient {
    var start = color
    start[keyPath: keyPath] = 0.0
    var end = color
    end[keyPath: keyPath] = 1.0
    return LinearGradient(colors: [Color.from(simd4: start), Color.from(simd4: end)], startPoint: .init(x: 0, y: 0.5), endPoint: .init(x: 1.0, y: 0.5))
}

private func opaqueColor(_ color: SIMD4<Float>) -> SIMD4<Float> {
    var color = color
    color.w = 1.0
    return color
}

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

struct StrokePresetsMenu: View {

    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?
    @State private var isShowingPopover = false

    var body: some View {
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
    }
}

struct StrokeEditingView: View {
    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?

    var body: some View {
        Text("Stroke")
            .font(.caption)
            .foregroundColor(.secondary)

        StrokeWidthEditor(width: $dataModel.strokeWidth)

        StrokeColorEditor(color: $dataModel.strokeColor)

        StrokePresetsMenu(dataModel: dataModel, delegate: delegate)
    }
}

struct MainToolsView: View {
    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?

    var body: some View {
        ForEach(ToolIdentifier.allCases) { id in
            Button(action: {
                delegate?.onClickTool(identifier: id)
            }, label: {
                Image(systemName: id.symbolName)
                    .foregroundColor(id == dataModel.activeToolIdentifier ? Color.accentColor : Color.primary)
            })
            .help(id.tooltip)
        }
    }
}


struct ImageEditingView: View {
    static let presetScales = [25, 50, 100, 125, 150]
    static let presetRotations = [90, 180, 270]

    @ObservedObject var imageItemProperty: ImageItemProperty
    weak var delegate: (any ToolbarDelegate)?
    
    var body: some View {
        HStack {
            Menu {
                ForEach(Self.presetScales, id: \.self) {scale in
                    Button(action: {
                        imageItemProperty.scale = CGFloat(scale)
                    }, label: {
                        Text("\(scale)%")
                    })
                }
            } label: {
                Text("Scale")
                    .font(.caption)
            }
            .frame(width: 65)

            Slider(value: $imageItemProperty.scale, in: 1...200)

            Spacer()

            Menu {
                ForEach(Self.presetRotations, id: \.self) { rotation in
                    Button(action: {
                        imageItemProperty.rotation = CGFloat(rotation)
                    }, label: {
                        Text("\(rotation)°")
                    })
                }
            } label: {
                Text("Rotation")
                    .font(.caption)
            }
            .frame(width: 70)

            Slider(value: $imageItemProperty.rotation, in: 0...359)

            Spacer()

            Button(action: {
                delegate?.commitActiveTool()
            }, label: {
                Text("Done")
            })
        }
        .frame(minWidth: 400.0)
    }
}

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

struct ToolbarControls: View {
    
    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal], showsIndicators: false) {
                HStack {
                    MainToolsView(dataModel: dataModel, delegate: delegate)
                    Spacer()
                    if dataModel.activeToolIdentifier == .image {
                        ImageEditingView(imageItemProperty: dataModel.imageItemProperty, delegate: delegate)
                    } else if dataModel.activeToolIdentifier == .eraser {
                        EraserWidthEditor(width: $dataModel.eraserWidth)
                    } else {
                        StrokeEditingView(dataModel: dataModel, delegate: delegate)
                    }
                    Spacer()
#if DEBUG
                    Button(action: {
                        delegate?.toggleDebug()
                    }, label: {
                        Image(systemName: "ladybug")
                    })
                    .help("Toggle debug")
#endif
                    ExportButton()
                        .help("Export")
                }
                .padding(.horizontal)
                .frame(minWidth: proxy.size.width)
                .frame(height: proxy.size.height)
            }
        }
    }
}

#Preview {
    let strokePresets = [
        StrokePreset(width: 2.0, color: presetColors[0]),
        StrokePreset(width: 4.0, color: presetColors[1]),
    ]
    Group {
        ToolbarControls(dataModel: ToolbarDataModel(strokeWidth: 2.0, strokeColor: presetColors[0], strokePresets: strokePresets, activeToolIdentifier: .eraser))
            .frame(width: 700, height: 40)

        ToolbarControls(dataModel: ToolbarDataModel(strokeWidth: 2.0, strokeColor: presetColors[1], strokePresets: strokePresets))
            .frame(width: 700, height: 40)

        ToolbarControls(dataModel: ToolbarDataModel( strokeWidth: 2.0, strokeColor: presetColors[1], strokePresets: strokePresets, activeToolIdentifier: .image))
            .frame(width: 700, height: 40)
    }
}
