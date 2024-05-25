//
//  ToolbarControls.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/5/25.
//

import SwiftUI

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
    
    @Binding var strokeWidth: CGFloat
    @Binding var color: Color

    let debugAction: () -> Void
    let exportButtonFrameLocator: FrameLocatorView
    let exportAction: () -> Void
    
    var body: some View {
        HStack {
            Slider(value: $strokeWidth, in: 1...32) {
                Text("Stroke")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 180)
            ColorPicker(selection: $color, supportsOpacity: false, label: {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
            })
            Spacer()
            #if DEBUG
            Button(action: debugAction, label: {
                Image(systemName: "ladybug")
            })
            #endif
            Button(action: exportAction, label: {
                Image(systemName: "square.and.arrow.up")
            })
            .overlay(exportButtonFrameLocator, alignment: .center)
        }
        .padding(.horizontal)
    }
}

#Preview {
    @State var strokeWidth: CGFloat = 2.0
    @State var color: Color = .blue
    
    return ToolbarControls(
        strokeWidth: $strokeWidth,
        color: $color,
        debugAction: {},
        exportButtonFrameLocator: FrameLocatorView(referenceViewSetter: {_ in }),
        exportAction: {}
    )
        .frame(width: 400, height: 40)
}
