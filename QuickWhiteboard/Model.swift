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
import simd

protocol RenderItem: AnyObject {
    var boundingRect: CGRect { get }
}

struct PointSample {
    let location: SIMD2<Float>
}

final class DrawingPath: RenderItem {
    private var points: [PointSample] = []
    
    let color: SIMD4<Float>
    let strokeWidth: Float
    
    private(set) var boundingRect: CGRect = CGRect.zero
    private var vertexes: [SIMD2<Float>] = []
    private var vertexBuffer: MTLBuffer?
    
    init(color: CGColor, strokeWidth: CGFloat) {
        assert(color.colorSpace?.model == .rgb && color.numberOfComponents >= 3)
        let components = color.components!
        self.color = .init(Float(components[0]), Float(components[1]), Float(components[2]), Float(color.numberOfComponents == 3 ? 1.0 : components[3]))
        self.strokeWidth = Float(strokeWidth)
    }

    
    private func generateTriangles(location: SIMD2<Float>, lastLocation: SIMD2<Float>?) -> [SIMD2<Float>] {
        var result: [SIMD2<Float>] = []
        let pointTriangleCount = max(Int(ceilf(Float.pi * strokeWidth / 2.0)), 4)
        let sectorAngle = Float.pi * 2.0 / Float(pointTriangleCount)
        var points: [SIMD2<Float>] = []
        let radius = strokeWidth / 2.0
        for i in 0..<pointTriangleCount {
            let angle = sectorAngle * Float(i)
            let x = location.x + cosf(angle) * radius
            let y = location.y + sinf(angle) * radius
            points.append(.init(x: x, y: y))
        }
        
        if let lastLocation {
            let v = normalize(location - lastLocation)
            let u = SIMD2<Float>(-v.y, v.x)
            let p0 = lastLocation + u * radius
            let p1 = lastLocation - u * radius
            let p2 = location + u * radius
            let p3 = location - u * radius
            result.append(p0)
            result.append(p1)
            result.append(p2)
            result.append(p2)
            result.append(p1)
            result.append(p3)
            for i in 0..<pointTriangleCount {
                let pi = points[i]
                let pj = points[(i + 1) % pointTriangleCount]
                if simd_dot(pi - location, v) >= 0 || simd_dot(pj - location, v) >= 0 {
                    result.append(location)
                    result.append(pi)
                    result.append(pj)
                }
            }
        } else {
            for i in 0..<pointTriangleCount {
                result.append(location)
                result.append(points[i])
                result.append(points[(i + 1) % pointTriangleCount])
            }
        }
        return result
    }
    
    func addPointSample(location: CGPoint) {
        let sampleLocation = SIMD2(Float(location.x), Float(location.y))
        let lastLocation = points.last?.location
        if let lastLocation {
            if simd_length(sampleLocation - lastLocation) < 1e-1 {
                return
            }
        }
        points.append(PointSample(location: sampleLocation))
        var x_left = boundingRect.minX
        var y_bottom = boundingRect.minY
        var x_right = boundingRect.maxX
        var y_top = boundingRect.maxY
        let vertexes = generateTriangles(location: sampleLocation, lastLocation: lastLocation)
        for vertex in vertexes {
            if self.vertexes.count == 0 {
                x_left = CGFloat(vertex.x)
                x_right = CGFloat(vertex.x)
                y_bottom = CGFloat(vertex.y)
                y_top = CGFloat(vertex.y)
            } else {
                x_left = min(CGFloat(vertex.x), x_left)
                x_right = max(CGFloat(vertex.x), x_right)
                y_bottom = min(CGFloat(vertex.y), y_bottom)
                y_top = max(CGFloat(vertex.y), y_top)
            }
        }
        self.vertexes.append(contentsOf: vertexes)
        boundingRect = CGRect(x: x_left, y: y_bottom, width: x_right - x_left, height: y_top - y_bottom)
        vertexBuffer = nil
    }
    
    func upload(to device: MTLDevice) -> (vetexBuffer: MTLBuffer, vertexCount: Int) {
        if vertexBuffer == nil {
            vertexBuffer = device.makeBuffer(bytes: &vertexes, length: MemoryLayout<SIMD2<Float>>.size * max(vertexes.count, 1))!
        }
        return (vertexBuffer!, vertexes.count)
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

    func upload(to device: MTLDevice) -> (texture: MTLTexture, vertexBuffer: MTLBuffer, uvBuffer: MTLBuffer, vertexCount: Int) {
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
        return (texture!, vertexBuffer!, uvBuffer!, 6)
    }
    
}
