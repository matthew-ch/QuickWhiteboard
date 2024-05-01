//
//  Renderer.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

import Foundation
import Metal
import MetalKit

final class Renderer {
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue
    
    private var simplePipelineState: MTLRenderPipelineState
    private var texturePipelineState: MTLRenderPipelineState
    
    init(with device: MTLDevice, pixelFormat: MTLPixelFormat) {
        self.device = device
        commandQueue = device.makeCommandQueue()!
        
        let defaultLibrary = device.makeDefaultLibrary()!
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "simpleVertex")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "simpleFragment")
        simplePipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .zero
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "textureVertex")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "textureFragment")
        texturePipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func render(in view: MTKView, items: [RenderItem], viewport: CGRect, debug: Bool = false) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return;
        }
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        var frameRect = SIMD4(Float(viewport.minX), Float(viewport.minY), Float(viewport.width), Float(viewport.height))
        encoder.setVertexBytes(&frameRect, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
        for item in items {
            if !viewport.intersects(item.boundingRect) {
                continue
            }
            if let path = item as? DrawingPath {
                encoder.setRenderPipelineState(simplePipelineState)
                let vertexBuffer = path.upload(to: device)
                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 1)
                var color = path.color
                encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
                encoder.drawPrimitives(type: debug ? .point : .lineStrip, vertexStart: 0, vertexCount: path.points.count)
            } else if let ir = item as? ImageRect {
                encoder.setRenderPipelineState(texturePipelineState)
                let (texture, vertexBuffer, uvBuffer) = ir.upload(to: device)
                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 1)
                encoder.setVertexBuffer(uvBuffer, offset: 0, index: 2)
                encoder.setFragmentTexture(texture, index: 0)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            }
        }
        encoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
