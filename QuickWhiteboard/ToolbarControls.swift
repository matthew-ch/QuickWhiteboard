//
//  ToolbarControls.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/5/25.
//

import SwiftUI

class ToolbarDataModel: ObservableObject {
    @Published var strokeWidth: CGFloat
    @Published var color: Color

    init(strokeWidth: CGFloat, color: Color) {
        self.strokeWidth = strokeWidth
        self.color = color
    }
}

protocol ToolbarDelegate: AnyObject {
    func toggleDebug() -> Void
    func setExportButtonLocatorView(_ view: NSView) -> Void
    func exportCanvas() -> Void
}

struct FrameLocatorView: NSViewRepresentable {
    typealias NSViewType = NSView
    
    let referenceViewSetter: (NSView) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        referenceViewSetter(view)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
    }
}

struct ToolbarControls: View {
    
    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: ToolbarDelegate?

    var body: some View {
        HStack {
            Slider(value: $dataModel.strokeWidth, in: 1...32) {
                Text("Stroke")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 180)
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
            #endif
            Button(action: {
                delegate?.exportCanvas()
            }, label: {
                Image(systemName: "square.and.arrow.up")
            })
            .overlay(FrameLocatorView(referenceViewSetter: { view in
                delegate?.setExportButtonLocatorView(view)
            }), alignment: .center)
        }
        .padding(.horizontal)
    }
}

#Preview {
    
    return ToolbarControls(dataModel: ToolbarDataModel(strokeWidth: 2.0, color: .red))
        .frame(width: 400, height: 40)
}
