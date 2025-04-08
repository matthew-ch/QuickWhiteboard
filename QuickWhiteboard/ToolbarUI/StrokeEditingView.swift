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

        StrokeWidthEditor(width: $dataModel.strokeWidth)

        StrokeColorEditor(color: $dataModel.strokeColor)

        StrokePresetsMenu(dataModel: dataModel, delegate: delegate)
    }
}
