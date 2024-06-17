//
//  ToolbarControls.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/5/25.
//

import SwiftUI

protocol ToolbarDelegate: AnyObject {
    func toggleDebug() -> Void
    func exportCanvas(_ sender: NSButton) -> Void
    func commitImageItemProperty() -> Void
    func onClickTool(identifier: ToolIdentifier) -> Void
}

struct ExportButton: NSViewRepresentable {
    weak var toolbarDelegate: (any ToolbarDelegate)?

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

struct MainToolbar: View {
    
    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?

    var body: some View {
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
            Slider(value: $dataModel.strokeWidth, in: 1...32) {
                Text("Stroke")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 180)
            ColorPicker(selection: $dataModel.color, supportsOpacity: false, label: {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
            })
            Spacer()
            #if DEBUG
            Button(action: {
                delegate?.toggleDebug()
            }, label: {
                Image(systemName: "ladybug")
            })
            .help("Toggle debug")
            #endif
            ExportButton(toolbarDelegate: delegate)
                .help("Export")
        }
        .padding(.horizontal)
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
    Group {
        ToolbarControls(dataModel: ToolbarDataModel(strokeWidth: 2.0, color: .red))
            .frame(width: 400, height: 40)
        
        ToolbarControls(dataModel: ToolbarDataModel(strokeWidth: 2.0, color: .red, imageItemProperty: ImageItemProperty()))
            .frame(width: 400, height: 40)
    }
}
