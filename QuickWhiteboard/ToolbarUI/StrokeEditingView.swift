//
//  StrokeEditingView.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//

import SwiftUI

struct StrokeEditingView: View {
    @ObservedObject var dataModel: ToolbarDataModel
    weak var delegate: (any ToolbarDelegate)?

    var body: some View {
        Text("Stroke")
            .font(.caption)
            .foregroundColor(.secondary)

        WidthEditor(width: $dataModel.strokeWidth, presets: [1,2,4,8,16,32], minimum: 1, maximum: 100)

        ColorEditor(color: $dataModel.strokeColor)

        StrokePresetsMenu(dataModel: dataModel, delegate: delegate)
    }
}
