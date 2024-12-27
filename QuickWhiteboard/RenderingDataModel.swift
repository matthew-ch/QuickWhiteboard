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
import Accelerate

@MainActor
protocol RenderItem: AnyObject, ToolEditingItem {
    var boundingRect: CGRect { get }
    var hidden: Bool { get set }
}

struct PointSample {
    let location: SIMD2<Float>
}

final class ErasedItems: ToolEditingItem {
    var selected: [any RenderItem] = []
    
    func erase() {
        for item in selected {
            item.hidden = true
        }
    }
    
    func restore() {
        for item in selected {
            item.hidden = false
        }
    }
}

final class DrawingItem: RenderItem {
    private(set) var points: [PointSample] = [] {
        didSet {
            vertexBuffer = nil
            updateBoundingRect()
        }
    }
    
    let color: SIMD4<Float>
    let strokeWidth: Float
    
    private(set) var boundingRect: CGRect = CGRect(origin: .init(x: CGFloat.infinity, y: CGFloat.infinity), size: .zero)
    var hidden: Bool = false

    private var vertexBuffer: (any MTLBuffer)?
    
    init(color: CGColor, strokeWidth: CGFloat) {
        assert(color.colorSpace?.model == .rgb && color.numberOfComponents >= 3)
        let components = color.components!
        self.color = .init(Float(components[0]), Float(components[1]), Float(components[2]), Float(color.numberOfComponents == 3 ? 1.0 : components[3]))
        self.strokeWidth = Float(strokeWidth)
    }
    
    private func updateBoundingRect() {
        if points.isEmpty {
            return
        }
        var minxy = SIMD2<Float>(x: Float.infinity, y: Float.infinity)
        var maxxy = SIMD2<Float>(x: -Float.infinity, y: -Float.infinity)
        for point in points {
            minxy = simd_min(minxy, point.location - strokeWidth)
            maxxy = simd_max(maxxy, point.location + strokeWidth)
        }
        boundingRect = CGRect(origin: .from(minxy), size: .from(maxxy - minxy))
    }
    
    private func generateTriangles(point: PointSample, previousPoint: PointSample?, nextPoint: PointSample?) -> [SIMD2<Float>] {
        let location = point.location
        let previousLocation = previousPoint?.location
        let nextLocation = nextPoint?.location

        let pointTriangleCount = max(Int(ceilf(Float.pi * strokeWidth / 2.0)), 4)
        let sectorAngle = Float.pi * 2.0 / Float(pointTriangleCount)
        let angles = (0..<pointTriangleCount).map({ sectorAngle * Float($0) })
        var cosValues = Array<Float>(repeating: 0.0, count: pointTriangleCount)
        var sinValues = Array<Float>(repeating: 0.0, count: pointTriangleCount)
        vForce.sincos(angles, sinResult: &sinValues, cosResult: &cosValues)

        var points: [SIMD2<Float>] = []
        for i in 0..<pointTriangleCount {
            points.append(.init(x: cosValues[i], y: sinValues[i]))
        }
        points.append(points[0])
        let radius = strokeWidth / 2.0
        var visibleIndices = Array(0..<pointTriangleCount)
        
        var result: [SIMD2<Float>] = []

        if let nextLocation {
            let v = normalize(location - nextLocation)
            visibleIndices = visibleIndices.filter { i in
                simd_dot(points[i], v) > 0 || simd_dot(points[i + 1], v) > 0
            }
        }

        if let previousLocation {
            let v = normalize(location - previousLocation)
            let u = SIMD2<Float>(-v.y, v.x)
            let p0 = previousLocation + u * radius
            let p1 = previousLocation - u * radius
            let p2 = location + u * radius
            let p3 = location - u * radius
            result.append(p0)
            result.append(p1)
            result.append(p2)
            result.append(p2)
            result.append(p1)
            result.append(p3)

            visibleIndices = visibleIndices.filter { i in
                simd_dot(points[i], v) > 0 || simd_dot(points[i + 1], v) > 0
            }
        }

        for i in visibleIndices {
            result.append(location)
            result.append(points[i] * radius + location)
            result.append(points[i + 1] * radius + location)
        }
        return result
    }
    
    private func generateVertexes() -> [SIMD2<Float>] {
        var result: [SIMD2<Float>] = []
        for i in 0..<points.count {
            let previousPoint = i == 0 ? nil : points[i - 1]
            let nextPoint = i + 1 < points.count ? points[i + 1] : nil
            result.append(contentsOf: generateTriangles(point: points[i], previousPoint: previousPoint, nextPoint: nextPoint))
        }
        return result
    }
    
    func addPointSample(location: CGPoint) {
        points.append(PointSample(location: location.float2))
    }
    
    func popLastSample() {
        _ = points.popLast()
    }
    
    func upload(to device: MTLDevice) -> (vetexBuffer: any MTLBuffer, vertexCount: Int) {
        if vertexBuffer == nil {
            let vertexes = generateVertexes()
            vertexBuffer = device.makeBuffer(bytes: vertexes, length: MemoryLayout<SIMD2<Float>>.size * max(vertexes.count, 1))!
        }
        return (vertexBuffer!, vertexBuffer!.length / MemoryLayout<SIMD2<Float>>.size)
    }
}

final class ImageItem: RenderItem {
    private(set) var image: CGImage
    var center: SIMD2<Float> {
        didSet {
            vertexBuffer = nil
            updateBoudingRect()
        }
    }
    let size: SIMD2<Float>
    var scale: Float = 1.0 {
        didSet {
            vertexBuffer = nil
            updateBoudingRect()
        }
    }
    var rotation: Float = 0.0 {
        didSet {
            vertexBuffer = nil
            updateBoudingRect()
        }
    }
    private(set) var boundingRect: CGRect = .zero
    var hidden: Bool = false

    private var texture: (any MTLTexture)?
    private var vertexBuffer: (any MTLBuffer)?
    private var uvBuffer: (any MTLBuffer)?
    
    static var textureLoader: MTKTextureLoader!
    static let uvs: [SIMD2<Float>] = [
        .init(0.0, 1.0),
        .init(1.0, 0.0),
        .init(0.0, 0.0),
        .init(1.0, 0.0),
        .init(0.0, 1.0),
        .init(1.0, 1.0),
    ]
    
    init(image: CGImage, center: SIMD2<Float>, size: SIMD2<Float>) {
        self.image = image
        self.center = center
        self.size = size
        self.updateBoudingRect()
    }
    
    private func updateBoudingRect() {
        let matrix = matrix2DRotateAndScale(radian: rotation, scale: scale)
        let p1 = simd_mul(matrix, size * 0.5)
        let p2 = simd_mul(matrix, size * SIMD2(0.5, -0.5))
        let dx = max(abs(p1.x), abs(p2.x))
        let dy = max(abs(p1.y), abs(p2.y))
        let half_size = SIMD2(dx, dy)
        boundingRect = .init(origin: .from(center - half_size), size: .from(half_size * 2.0))
    }

    func upload(to device: MTLDevice) -> (texture: any MTLTexture, vertexBuffer: any MTLBuffer, uvBuffer: any MTLBuffer, vertexCount: Int) {
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
            let matrix = matrix2DRotateAndScale(radian: rotation, scale: scale)
            let p1 = simd_mul(matrix, size * 0.5)
            let p2 = simd_mul(matrix, size * SIMD2(0.5, -0.5))

            let vertexes: [SIMD2<Float>] = [
                center - p1,
                center + p1,
                center - p2,
                center + p1,
                center - p1,
                center + p2,
            ]
            vertexBuffer = device.makeBuffer(bytes: vertexes, length: MemoryLayout<SIMD2<Float>>.size * 6)
        }
        if uvBuffer == nil {
            uvBuffer = device.makeBuffer(bytes: Self.uvs, length: MemoryLayout<SIMD2<Float>>.size * 6)
        }
        return (texture!, vertexBuffer!, uvBuffer!, 6)
    }
    
}
