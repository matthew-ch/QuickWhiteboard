//
//  Renderer.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

import Foundation
import Metal
import MetalKit

private let sampleCount = 4

@MainActor
final class Renderer {
    private var device: any MTLDevice
    private var pixelFormat: MTLPixelFormat
    private var commandQueue: any MTLCommandQueue
    
    private var simplePipelineState: any MTLRenderPipelineState
    private var alphaPipelineState: any MTLRenderPipelineState
    private var texturePipelineState: any MTLRenderPipelineState
    private var depthStentilState: any MTLDepthStencilState

    private var onScreenRenderPassDescriptor: MTLRenderPassDescriptor!
    private var onScreenResolvedTexture: (any MTLTexture)!
    
    init(with device: any MTLDevice, pixelFormat: MTLPixelFormat) {
        self.device = device
        self.pixelFormat = pixelFormat
        commandQueue = device.makeCommandQueue()!
        
        let defaultLibrary = device.makeDefaultLibrary()!
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineDescriptor.rasterSampleCount = sampleCount
        pipelineDescriptor.depthAttachmentPixelFormat = .depth16Unorm

        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "simpleVertex")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "simpleFragment")
        simplePipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .zero
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        alphaPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "textureVertex")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "textureFragment")
        texturePipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilDescriptor.depthCompareFunction = .greater
        depthStentilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }
    
    private func makeRenderPassDescriptor(size: CGSize) -> (MTLRenderPassDescriptor, any MTLTexture) {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: Int(size.width), height: Int(size.height), mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.textureType = .type2DMultisample
        textureDescriptor.sampleCount = sampleCount
        textureDescriptor.storageMode = .memoryless
        let multiSampleTexture = device.makeTexture(descriptor: textureDescriptor)!

        textureDescriptor.pixelFormat = .depth16Unorm
        let depthTexture = device.makeTexture(descriptor: textureDescriptor)!

        textureDescriptor.pixelFormat = pixelFormat
        textureDescriptor.textureType = .type2D
        textureDescriptor.sampleCount = 1
        textureDescriptor.storageMode = .shared
        let resolvedTexture = device.makeTexture(descriptor: textureDescriptor)!

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = multiSampleTexture
        renderPassDescriptor.colorAttachments[0].resolveTexture = resolvedTexture
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve

        let depthAttachment = MTLRenderPassDepthAttachmentDescriptor()
        depthAttachment.clearDepth = 0.0
        depthAttachment.texture = depthTexture
        depthAttachment.loadAction = .clear
        depthAttachment.storeAction = .dontCare
        renderPassDescriptor.depthAttachment = depthAttachment

        return (renderPassDescriptor, resolvedTexture)
    }
    
    func updateOnScreenDrawableSize(_ size: CGSize) {
        (onScreenRenderPassDescriptor, onScreenResolvedTexture) = makeRenderPassDescriptor(size: size)
    }
    
    func render(in view: MTKView, items: [any RenderItem], viewport: CGRect, debug: Bool = false) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: onScreenRenderPassDescriptor)!
        encoder.setTriangleFillMode(debug ? .lines : .fill)
        render(with: encoder, items: items, viewport: viewport)
        encoder.endEncoding()
        defer {
            commandBuffer.commit()
        }
        guard let currentDrawable = view.currentDrawable else {
            return;
        }
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        blitEncoder.copy(from: onScreenResolvedTexture, to: currentDrawable.texture)
        blitEncoder.endEncoding()
        commandBuffer.present(currentDrawable)
    }
    
    func renderOffscreen(of size: CGSize, items: [any RenderItem], viewport: CGRect) -> any MTLTexture {
        let (renderPassDescriptor, resolvedTexture) = makeRenderPassDescriptor(size: size)
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        render(with: encoder, items: items, viewport: viewport)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return resolvedTexture
    }
    
    private func render(with encoder: MTLRenderCommandEncoder, items: [any RenderItem], viewport: CGRect) {
        var frameRect = SIMD4(Float(viewport.minX), Float(viewport.minY), Float(viewport.width), Float(viewport.height))
        encoder.setVertexBytes(&frameRect, length: MemoryLayout<SIMD4<Float>>.size, index: Int(BufferIndexViewport.rawValue))
        encoder.setDepthStencilState(depthStentilState)
        let total = Float(items.count)
        var alphaItems: [(Float, any RenderItem)] = []

        encoder.setRenderPipelineState(simplePipelineState)
        for (i, item) in items.enumerated().reversed() {
            if item.hidden || !viewport.intersects(item.boundingRect) {
                continue
            }
            var depth = Float(i + 1) / total
            encoder.setVertexBytes(&depth, length: MemoryLayout<Float>.size, index: Int(BufferIndexDepth.rawValue))
            if let drawing = item as? DrawingItem {
                if drawing.strokeColor.w != 1.0 {
                    alphaItems.append((depth, item))
                    continue
                }
                let (vertexBuffer, vertexCount) = drawing.upload(to: device)
                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(BufferIndexVertexArray.rawValue))
                var color = drawing.strokeColor
                encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: Int(BufferIndexColor.rawValue))
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
            } else {
                alphaItems.append((depth, item))
            }
        }
        for (depth, item) in alphaItems.reversed() {
            var depth = depth
            encoder.setVertexBytes(&depth, length: MemoryLayout<Float>.size, index: Int(BufferIndexDepth.rawValue))
            if let drawing = item as? DrawingItem {
                encoder.setRenderPipelineState(alphaPipelineState)
                let (vertexBuffer, vertexCount) = drawing.upload(to: device)
                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(BufferIndexVertexArray.rawValue))
                var color = drawing.strokeColor
                encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: Int(BufferIndexColor.rawValue))
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
            } else if let image = item as? ImageItem {
                encoder.setRenderPipelineState(texturePipelineState)
                let (texture, vertexBuffer, uvBuffer, vertexCount) = image.upload(to: device)
                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(BufferIndexVertexArray.rawValue))
                encoder.setVertexBuffer(uvBuffer, offset: 0, index: Int(BufferIndexUVArray.rawValue))
                encoder.setFragmentTexture(texture, index: Int(TextureIndexDefault.rawValue))
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
            }
        }
    }
}
