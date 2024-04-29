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
        
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "textureVertex")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "textureFragment")
        texturePipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func render(in view: MTKView, paths: [DrawingPath], viewport: CGRect, debug: Bool = false) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return;
        }
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        encoder.setRenderPipelineState(simplePipelineState)
        var frameRect = SIMD4(Float(viewport.minX), Float(viewport.minY), Float(viewport.width), Float(viewport.height))
        encoder.setVertexBytes(&frameRect, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
        for path in paths {
            if !viewport.intersects(path.boundingRect) {
                continue
            }
            encoder.setVertexBuffer(path.uploadToBuffer(device: device), offset: 0, index: 1)
            var color = path.color
            encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            encoder.drawPrimitives(type: debug ? .point : .lineStrip, vertexStart: 0, vertexCount: path.points.count)
        }
        encoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
