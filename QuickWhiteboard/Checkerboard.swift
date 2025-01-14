//
//  Checkerboard.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/1/14.
//

import SwiftUI

private struct CheckboardGrid: Shape {

    let cellLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows = Int(ceil(rect.height / cellLength))
        let cols = Int(ceil(rect.width / cellLength))
        for col in 0..<cols {
            let x = cellLength * CGFloat(col)
            for row in 0..<rows {
                if (row + col).isMultiple(of: 2) {
                    let y = cellLength * CGFloat(row)
                    path.addRect(CGRect(x: x, y: y, width: cellLength, height: cellLength))
                }
            }
        }
        return path
    }
}

struct Checkerboard: View {
    let cellLength: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color

    init(cellLength: CGFloat, backgroundColor: Color = .white, foregroundColor: Color = .gray) {
        self.cellLength = cellLength
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        Rectangle()
            .fill(backgroundColor)
            .overlay(
                CheckboardGrid(cellLength: cellLength)
                    .fill(foregroundColor)
            )
    }
}

#Preview {
    Checkerboard(cellLength: 10.0)
        .frame(width: 256.0, height: 40.0)
}
