//
//  GridItem.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/3.
//

import Foundation
import Metal

final class GridItem: RenderItem {

    var globalPosition: CGPoint {
        get {
            .zero
        }
        set {
            fatalError("does not support setting position")
        }
    }

    var localBoundingRect: CGRect
    
    var hidden: Bool = false

    var frozen: Bool = true

    var isOpaque: Bool {
        true
    }

    var color: SIMD4<Float> = .zero

    var spacing: CGFloat = 20.0

    private var vertexBuffer: (any MTLBuffer)?

    init(boundingRect: CGRect) {
        self.localBoundingRect = boundingRect
    }

    func distance(to globalLocation: CGPoint) -> Float {
        .infinity
    }

    func upload(to device: MTLDevice) -> (vetexBuffer: any MTLBuffer, vertexCount: Int) {
        let vLineCount = Int(localBoundingRect.width / spacing) + 1
        let hLineCount = Int(localBoundingRect.height / spacing) + 1
        let vLineStartX = Float(ceil(localBoundingRect.minX / spacing) * spacing)
        let vLineBottomY = Float(localBoundingRect.minY)
        let vLineTopY = Float(localBoundingRect.maxY)
        let hLineStartY = Float(ceil(localBoundingRect.minY / spacing) * spacing)
        let hLineLeftX = Float(localBoundingRect.minX)
        let hLineRightX = Float(localBoundingRect.maxX)
        let vertexCount = (vLineCount + hLineCount) * 2
        let size = vertexCount * MemoryLayout<Point2D>.size
        if vertexBuffer == nil || vertexBuffer!.length < size {
            vertexBuffer = device.makeBuffer(length: size, options: .storageModeShared)
        }
        vertexBuffer!.contents().withMemoryRebound(to: Point2D.self, capacity: vertexCount) { pointer in
            for i in 0..<vLineCount {
                let x = Float(i) * Float(spacing) + vLineStartX
                pointer[2 * i].x = x
                pointer[2 * i].y = vLineBottomY
                pointer[2 * i + 1].x = x
                pointer[2 * i + 1].y = vLineTopY
            }
            let offset = 2 * vLineCount
            for i in 0..<hLineCount {
                let y = Float(i) * Float(spacing) + hLineStartY
                pointer[offset + 2 * i].x = hLineLeftX
                pointer[offset + 2 * i].y = y
                pointer[offset + 2 * i + 1].x = hLineRightX
                pointer[offset + 2 * i + 1].y = y
            }
        }
        return (vertexBuffer!, vertexCount)
    }

}
