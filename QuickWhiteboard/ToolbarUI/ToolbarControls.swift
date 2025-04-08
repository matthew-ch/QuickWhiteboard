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
    func addStrokePreset() -> Void
    func removeStrokePreset(preset: StrokePreset) -> Void
    func onClickTool(identifier: ToolIdentifier) -> Void
    func commitActiveTool() -> Void
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

struct ToolbarControls: View {
    
    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal], showsIndicators: false) {
                HStack {
                    MainToolsView(dataModel: dataModel, delegate: delegate)
                    Divider()
                        .frame(height: 16.0)
                        .padding(.horizontal, 8.0)
                    if dataModel.activeToolIdentifier == .image {
                        ImageEditingView(imageItemProperty: dataModel.imageItemProperty, delegate: delegate)
                    } else if dataModel.activeToolIdentifier == .eraser {
                        EraserWidthEditor(width: $dataModel.eraserWidth)
                    } else if dataModel.activeToolIdentifier != .cursor {
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
        StrokePreset(width: 4.0, color: presetColors[2]),
        StrokePreset(width: 4.0, color: presetColors[3]),
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
