//
//  Model.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

import Foundation
import CoreGraphics
import Metal

struct PointSample {
    let location: SIMD2<Float>
}

final class DrawingPath {
    private(set) var points: [PointSample] = []
    
    let color: SIMD4<Float>
    let strokeWidth: Float
    
    private(set) var boundingRect: CGRect = CGRect.zero
    
    init(color: CGColor, strokeWidth: CGFloat) {
        assert(color.colorSpace?.model == .rgb && color.numberOfComponents >= 3)
        let components = color.components!
        self.color = .init(Float(components[0]), Float(components[1]), Float(components[2]), Float(color.numberOfComponents == 3 ? 1.0 : components[3]))
        self.strokeWidth = Float(strokeWidth)
    }
    
    func addPointSample(location: CGPoint) {
        let sampleLocation = SIMD2(Float(location.x), Float(location.y))
        points.append(PointSample(location: sampleLocation))
        var x_left = boundingRect.minX
        var y_bottom = boundingRect.minY
        var x_right = boundingRect.maxX
        var y_top = boundingRect.maxY
        if points.count == 1 {
            x_left = location.x
            x_right = location.x
            y_bottom = location.y
            y_top = location.y
        } else {
            x_left = min(location.x, x_left)
            x_right = max(location.x, x_right)
            y_bottom = min(location.y, y_bottom)
            y_top = max(location.y, y_top)
        }
        boundingRect = CGRect(x: x_left, y: y_bottom, width: x_right - x_left, height: y_top - y_bottom)
    }
    
    func uploadToBuffer(device: MTLDevice) -> MTLBuffer {
        let buffer = device.makeBuffer(bytes: &points, length: MemoryLayout<PointSample>.size * points.count)!
        return buffer
    }
}
