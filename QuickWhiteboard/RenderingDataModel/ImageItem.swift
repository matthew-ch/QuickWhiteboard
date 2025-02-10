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
    let size: SIMD2<Float>

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
    static let uvs: [SIMD2<Float>] = [
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

    init(image: CGImage, position: CGPoint, size: SIMD2<Float>) {
        self.image = image
        self.globalPosition = position
        self.size = size
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
        let matrix = matrix2DRotateAndScale(radian: rotation, scale: scale)
        let p1 = simd_mul(matrix, size * 0.5)
        let p2 = simd_mul(matrix, size * SIMD2(0.5, -0.5))

        let vertexes: [SIMD2<Float>] = [
            -p1,
            p1,
            -p2,
            p1,
            -p1,
            p2,
        ]
        return device!.makeBuffer(bytes: vertexes, length: MemoryLayout<SIMD2<Float>>.size * 6)!
    }

    private var resolvedUVBuffer: any MTLBuffer {
        device!.makeBuffer(bytes: Self.uvs, length: MemoryLayout<SIMD2<Float>>.size * 6)!
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
