//
//  ToolbarControls.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/5/25.
//

import SwiftUI

class ImageItemProperty: ObservableObject {
    @Published var scale: CGFloat = 100.0
    @Published var rotation: CGFloat = 0.0
}

class ToolbarDataModel: ObservableObject {
    @Published var strokeWidth: CGFloat
    @Published var color: Color
    @Published var imageItemProperty: ImageItemProperty?

    init(strokeWidth: CGFloat, color: Color, imageItemProperty: ImageItemProperty? = nil) {
        self.strokeWidth = strokeWidth
        self.color = color
        self.imageItemProperty = imageItemProperty
    }
}

protocol ToolbarDelegate: AnyObject {
    func toggleDebug() -> Void
    func setExportButtonLocatorView(_ view: NSView) -> Void
    func exportCanvas() -> Void
    func commitImageItemProperty() -> Void
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

struct MainToolbar: View {
    
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

private let presetScales: [Int] = [25, 50]
private let presetRotations: [Int] = [90, 180, 270]

struct ImageEditToolbar: View {
    @ObservedObject var imageItemProperty: ImageItemProperty
    weak var delegate: ToolbarDelegate?
    
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
    weak var delegate: ToolbarDelegate?
    
    var body: some View {
        if let property = dataModel.imageItemProperty {
            ImageEditToolbar(imageItemProperty: property, delegate: delegate)
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
