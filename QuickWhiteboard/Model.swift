//
//  Model.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

import Foundation
import CoreGraphics
import Metal
import MetalKit

protocol RenderItem: AnyObject {
    var boundingRect: CGRect { get }
}

struct PointSample {
    let location: SIMD2<Float>
}

final class DrawingPath: RenderItem {
    private(set) var points: [PointSample] = []
    
    let color: SIMD4<Float>
    let strokeWidth: Float
    
    private(set) var boundingRect: CGRect = CGRect.zero
    
    private var vertexBuffer: MTLBuffer?
    
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
        vertexBuffer = nil
    }
    
    func upload(to device: MTLDevice) -> MTLBuffer {
        if vertexBuffer == nil {
            vertexBuffer = device.makeBuffer(bytes: &points, length: MemoryLayout<PointSample>.size * points.count)!
        }
        return self.vertexBuffer!
    }
}

final class ImageRect: RenderItem {
    private(set) var image: CGImage
    var boundingRect: CGRect
    
    private var texture: MTLTexture?
    private var vertexBuffer: MTLBuffer?
    private var uvBuffer: MTLBuffer?
    
    static var textureLoader: MTKTextureLoader!
    static let uvs: [SIMD2<Float>] = [
        .init(0.0, 1.0),
        .init(1.0, 0.0),
        .init(0.0, 0.0),
        .init(1.0, 0.0),
        .init(0.0, 1.0),
        .init(1.0, 1.0),
    ]
    
    init(image: CGImage, boundingRect: CGRect) {
        self.image = image
        self.boundingRect = boundingRect
    }

    func upload(to device: MTLDevice) -> (texture: MTLTexture, vertexBuffer: MTLBuffer, uvBuffer: MTLBuffer) {
        if Self.textureLoader == nil {
            Self.textureLoader = MTKTextureLoader(device: device)
        }
        if texture == nil {
            texture = try! Self.textureLoader.newTexture(cgImage: image, options: [
                .allocateMipmaps: NSNumber(booleanLiteral: false),
                .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                .SRGB: NSNumber(booleanLiteral: false),
            ])
        }
        if vertexBuffer == nil {
            let origin = boundingRect.origin.float2
            let size = boundingRect.size.float2
            let vertexes: [SIMD2<Float>] = [
                origin,
                origin + size,
                .init(origin.x, origin.y + size.y),
                origin + size,
                origin,
                .init(origin.x + size.x, origin.y)
            ]
            vertexBuffer = device.makeBuffer(bytes: vertexes, length: MemoryLayout<SIMD2<Float>>.size * 6)
        }
        if uvBuffer == nil {
            uvBuffer = device.makeBuffer(bytes: Self.uvs, length: MemoryLayout<SIMD2<Float>>.size * 6)
        }
        return (texture!, vertexBuffer!, uvBuffer!)
    }
    
}
