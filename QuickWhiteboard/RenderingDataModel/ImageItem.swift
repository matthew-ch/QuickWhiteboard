//
//  ImageItem.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/3.
//

import Foundation
import CoreGraphics
import Metal
import MetalKit
import simd

final class ImageItem: RenderItem, CanMarkAsDirty, HasGeneration {
    private(set) var image: CGImage
    var globalPosition: CGPoint = .zero
    let size: Size2D

    @DirtyMarking
    var scale: Float = 1.0

    @DirtyMarking
    var rotation: Float = 0.0

    @OnDemand(\ImageItem.resolvedBoundingRect)
    private var _boundingRect: CGRect
    var localBoundingRect: CGRect {
        _boundingRect
    }

    var hidden: Bool = false

    var frozen: Bool = true

    var isOpaque: Bool {
        false
    }

    private var device: (any MTLDevice)?

    @OnDemand(\ImageItem.resolvedTexture, once: true)
    private var texture: (any MTLTexture)

    @OnDemand(\ImageItem.resolvedVertexBuffer)
    private var vertexBuffer: (any MTLBuffer)

    @OnDemand(\ImageItem.resolvedUVBuffer, once: true)
    private var uvBuffer: (any MTLBuffer)
    
    static var textureLoader: MTKTextureLoader!
    static let uvs: [Point2D] = [
        .init(0.0, 1.0),
        .init(1.0, 0.0),
        .init(0.0, 0.0),
        .init(1.0, 0.0),
        .init(0.0, 1.0),
        .init(1.0, 1.0),
    ]

    private(set) var generation: Int = 1

    func markAsDirty() {
        generation += 1
    }

    init(image: CGImage, position: CGPoint, size: Size2D) {
        self.image = image
        self.globalPosition = position
        self.size = size
    }

    func distance(to globalLocation: CGPoint) -> Float {
        let location = globalLocation.float2 - globalPosition.float2
        let (p1, p2) = calculateP1P2()
        let dist = min(
            distanceFromPointToLineSegment(point: location, segmentPoints: p1, p2),
            distanceFromPointToLineSegment(point: location, segmentPoints: p1, -p2),
            distanceFromPointToLineSegment(point: location, segmentPoints: -p1, p2),
            distanceFromPointToLineSegment(point: location, segmentPoints: -p1, -p2)
        )
        if isPointInside(point: location, p1: p1, p2: p2, p3: -p1) || isPointInside(point: location, p1: p1, p2: -p1, p3: -p2) {
            return -dist
        } else {
            return dist
        }
    }

    private func calculateP1P2() -> (Point2D, Point2D) {
        let matrix = matrix2DRotateAndScale(radian: rotation, scale: scale)
        let p1 = simd_mul(matrix, size * 0.5)
        let p2 = simd_mul(matrix, size * SIMD2(0.5, -0.5))
        return (p1, p2)
    }

    private var resolvedTexture: any MTLTexture {
        try! Self.textureLoader.newTexture(cgImage: image, options: [
            .allocateMipmaps: NSNumber(booleanLiteral: false),
            .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .SRGB: NSNumber(booleanLiteral: false),
        ])
    }

    private var resolvedVertexBuffer: any MTLBuffer {
        let (p1, p2) = calculateP1P2()

        let vertexes: [Point2D] = [
            -p1,
            p1,
            -p2,
            p1,
            -p1,
            p2,
        ]
        return device!.makeBuffer(bytes: vertexes, length: MemoryLayout<Point2D>.size * 6)!
    }

    private var resolvedUVBuffer: any MTLBuffer {
        device!.makeBuffer(bytes: Self.uvs, length: MemoryLayout<Point2D>.size * 6)!
    }

    private var resolvedBoundingRect: CGRect {
        let matrix = matrix2DRotateAndScale(radian: rotation, scale: scale)
        let p1 = simd_mul(matrix, size * 0.5)
        let p2 = simd_mul(matrix, size * SIMD2(0.5, -0.5))
        let dx = max(abs(p1.x), abs(p2.x))
        let dy = max(abs(p1.y), abs(p2.y))
        let half_size = SIMD2(dx, dy)
        return .init(origin: .from(-half_size), size: .from(half_size * 2.0))
    }

    func upload(to device: MTLDevice) -> (texture: any MTLTexture, vertexBuffer: any MTLBuffer, uvBuffer: any MTLBuffer, vertexCount: Int) {
        if Self.textureLoader == nil {
            Self.textureLoader = MTKTextureLoader(device: device)
        }
        self.device = device
        return (texture, vertexBuffer, uvBuffer, 6)
    }
}
