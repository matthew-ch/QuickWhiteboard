//
//  WidthEditor.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//
import SwiftUI

@MainActor private var formatterCache: [String: NumberFormatter] = [:]

struct WidthEditor: View {

    @Binding var width: CGFloat
    let presets: [Int]
    let minimum: Int
    let maximum: Int
    var titleKey: String = "Width"
    var isInline: Bool = false

    @State private var isShowingPopover = false

    private var formatter: NumberFormatter {
        if let formatter = formatterCache["\((minimum, maximum))"] {
            return formatter
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = minimum as NSNumber
        formatter.maximum = maximum as NSNumber
        formatterCache["\((minimum, maximum))"] = formatter
        return formatter
    }

    @ViewBuilder
    private var presetsView: some View {
        ForEach(presets, id: \.self) { i in
            Button {
                width = CGFloat(i)
                isShowingPopover = false
            } label: {
                Text("\(i)")
            }
        }
    }

    @ViewBuilder
    private var customizeView: some View {
        Text("Customize")
            .font(.caption)
        TextField(titleKey, value: $width, formatter: formatter)
            .frame(width: 32)
    }

    var body: some View {
        if isInline {
            Text(titleKey)
                .font(.caption)
                .foregroundColor(.secondary)

            presetsView

            customizeView
        } else {
            Button {
                isShowingPopover = true
            } label: {
                Text("\(formatter.string(from: width as NSNumber)!)")
                    .frame(minWidth: 16.0)
            }
            .help(titleKey)
            .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
                VStack(spacing: 8.0) {
                    HStack {
                        presetsView
                    }
                    HStack {
                        customizeView
                    }
                }
                .padding(.all, 12.0)
            }
        }
    }
}


#Preview {
    HStack {
        WidthEditor(width: Binding.constant(10), presets: [10,20,30], minimum: 10, maximum: 100)
    }

    HStack {
        WidthEditor(width: Binding.constant(10), presets: [10,20,30], minimum: 10, maximum: 100, isInline: true)
    }
}
