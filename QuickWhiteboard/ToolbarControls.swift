//
//  ToolbarControls.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/5/25.
//

import SwiftUI

@MainActor
protocol ToolbarDelegate: AnyObject {
    func toggleDebug() -> Void
    func exportCanvas(_ sender: NSButton) -> Void
    func commitImageItemProperty() -> Void
    func addStrokePreset() -> Void
    func removeStrokePreset(preset: StrokePreset) -> Void
    func onClickTool(identifier: ToolIdentifier) -> Void
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

struct StrokePresetsMenu: View {

    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?
    @State private var isShowingPopover = false

    var body: some View {
        Button {
            self.isShowingPopover = true
        } label: {
            Image(systemName: "pencil.tip.crop.circle")
                .help("Presets")
        }
        .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
            VStack(spacing: 4.0) {
                Button {
                    delegate?.addStrokePreset()
                } label: {
                    HStack(alignment: .center, spacing: 2.0) {
                        Text("\(Int(dataModel.strokeWidth))")
                            .frame(width: 24.0)
                        Rectangle()
                            .fill(dataModel.strokeColor)
                            .frame(width: 32.0, height: 16.0)
                        Image(systemName: "plus.circle")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.plain)

                if dataModel.strokePresets.count > 0 {
                    Divider()
                }

                ForEach(dataModel.strokePresets) { stroke in
                    Button {
                        dataModel.strokeWidth = stroke.width
                        dataModel.strokeColor = Color(stroke.color)
                    } label: {
                        HStack(alignment: .center, spacing: 2.0) {
                            Text("\(Int(stroke.width))")
                                .frame(width: 24.0)
                            Rectangle()
                                .fill(Color(stroke.color))
                                .brightness(0)
                                .frame(width: 32.0, height: 16.0)
                            Button {
                                delegate?.removeStrokePreset(preset: stroke)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.all, 6.0)
        }
    }
}

struct MainToolbar: View {
    static let formatter = {
        let formatter = NumberFormatter()
        formatter.maximumIntegerDigits = 2
        formatter.numberStyle = .none
        formatter.minimum = 1
        formatter.maximum = 99
        return formatter
    }()

    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?

    var body: some View {
        GeometryReader { proxy in
            HStack {
                ForEach(ToolIdentifier.allCases) { id in
                    Button(action: {
                        delegate?.onClickTool(identifier: id)
                    }, label: {
                        Image(systemName: id.symbolName)
                            .foregroundColor(id == dataModel.activeToolIdentifier ? Color.accentColor : Color.primary)
                    })
                    .help(id.tooltip)
                }
                Spacer()
                if proxy.size.width >= 500 {
                    Text("Stroke")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                TextField("Width", value: $dataModel.strokeWidth, formatter: Self.formatter)
                    .frame(width: 32)
                    .help("Width")

                ColorPicker(selection: $dataModel.strokeColor, supportsOpacity: false, label: {})
                    .help("Color")

                StrokePresetsMenu(dataModel: dataModel, delegate: delegate)

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
            .frame(height: proxy.size.height)
            .padding(.horizontal)
        }
    }
}

private let presetScales: [Int] = [25, 50]
private let presetRotations: [Int] = [90, 180, 270]

struct ImageEditToolbar: View {
    @ObservedObject var imageItemProperty: ImageItemProperty
    weak var delegate: (any ToolbarDelegate)?
    
    var body: some View {
        HStack {
            Menu {
                ForEach(presetScales, id: \.self) {scale in
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

            Slider(value: $imageItemProperty.scale, in: 1...100)
            
            Spacer()
            
            Menu {
                ForEach(presetRotations, id: \.self) { rotation in
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
            
            Slider(value: $imageItemProperty.rotation, in: 0...360)
            
            Spacer()
            
            Button(action: {
                delegate?.commitImageItemProperty()
            }, label: {
                Text("Done")
            })
            
        }
        .padding(.horizontal)
    }
}

struct ToolbarControls: View {
    
    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?
    
    var body: some View {
        if dataModel.activeToolIdentifier == .image {
            ImageEditToolbar(imageItemProperty: dataModel.imageItemProperty, delegate: delegate)
        } else {
            MainToolbar(dataModel: dataModel, delegate: delegate)
        }
    }
}

#Preview {
    let strokePresets = [
        StrokePreset(width: 2.0, color: NSColor.red),
        StrokePreset(width: 4.0, color: NSColor.green)
    ]
    Group {
        ToolbarControls(dataModel: ToolbarDataModel(strokeWidth: 2.0, strokeColor: .red, strokePresets: strokePresets))
            .frame(width: 499, height: 40)

        ToolbarControls(dataModel: ToolbarDataModel(strokeWidth: 2.0, strokeColor: .red, strokePresets: strokePresets))
            .frame(width: 700, height: 40)
    }
}
