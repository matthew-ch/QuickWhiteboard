//
//  ImageEditingView.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//

import SwiftUI

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
