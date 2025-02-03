//
//  GridItem.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/3.
//

import Foundation
import Metal

private let gridSpacing = 20.0

final class GridItem: RenderItem {

    var boundingRect: CGRect
    
    var hidden: Bool = false

    var isOpaque: Bool {
        true
    }

    let color = SIMD4<Float>(x: 0.75, y: 0.75, z: 0.75, w: 1.0)

    private var vertexBuffer: (any MTLBuffer)?

    init(boundingRect: CGRect) {
        self.boundingRect = boundingRect
    }

    func upload(to device: MTLDevice) -> (vetexBuffer: any MTLBuffer, vertexCount: Int) {
        let vLineCount = Int(boundingRect.width / gridSpacing) + 1
        let hLineCount = Int(boundingRect.height / gridSpacing) + 1
        let vLineStartX = Float(ceil(boundingRect.minX / gridSpacing) * gridSpacing)
        let vLineBottomY = Float(boundingRect.minY)
        let vLineTopY = Float(boundingRect.maxY)
        let hLineStartY = Float(ceil(boundingRect.minY / gridSpacing) * gridSpacing)
        let hLineLeftX = Float(boundingRect.minX)
        let hLineRightX = Float(boundingRect.maxX)
        let vertexCount = (vLineCount + hLineCount) * 2
        let size = vertexCount * MemoryLayout<SIMD2<Float>>.size
        if vertexBuffer == nil || vertexBuffer!.length < size {
            vertexBuffer = device.makeBuffer(length: size, options: .storageModeShared)
        }
        vertexBuffer!.contents().withMemoryRebound(to: SIMD2<Float>.self, capacity: vertexCount) { pointer in
            for i in 0..<vLineCount {
                let x = Float(i) * Float(gridSpacing) + vLineStartX
                pointer[2 * i].x = x
                pointer[2 * i].y = vLineBottomY
                pointer[2 * i + 1].x = x
                pointer[2 * i + 1].y = vLineTopY
            }
            let offset = 2 * vLineCount
            for i in 0..<hLineCount {
                let y = Float(i) * Float(gridSpacing) + hLineStartY
                pointer[offset + 2 * i].x = hLineLeftX
                pointer[offset + 2 * i].y = y
                pointer[offset + 2 * i + 1].x = hLineRightX
                pointer[offset + 2 * i + 1].y = y
            }
        }
        return (vertexBuffer!, vertexCount)
    }

}
