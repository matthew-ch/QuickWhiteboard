//
//  ViewController.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/24.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    
    private var paths: [DrawingPath] = []
    private var renderer: Renderer!
    private var origin: CGPoint = .zero
    private var pendingPath: DrawingPath?
    
    private var color: CGColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    private var strokeWidth = 2.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let view = self.view as! MTKView
        let device = view.preferredDevice ?? MTLCreateSystemDefaultDevice()!
        view.device = device
        view.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        renderer = Renderer(with: device, pixelFormat: view.colorPixelFormat)
        view.delegate = self
        view.isPaused = true
        view.enableSetNeedsDisplay = true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func scrollWheel(with event: NSEvent) {
        let factor = event.hasPreciseScrollingDeltas ? 1.0 : 5.0
        origin.x -= event.scrollingDeltaX * factor
        origin.y += event.scrollingDeltaY * factor
        view.needsDisplay = true
    }
    
    private func convertEventLocation(_ location: NSPoint) -> CGPoint {
        let point = view.convert(location, from: nil)
        return CGPoint(x: point.x + origin.x, y: point.y + origin.y)
    }
    
    override func mouseDown(with event: NSEvent) {
        pendingPath = DrawingPath(color: color, strokeWidth: strokeWidth)
        pendingPath?.addPointSample(location: convertEventLocation(event.locationInWindow))
    }
    
    override func mouseUp(with event: NSEvent) {
        if let pendingPath = pendingPath {
            paths.append(pendingPath)
            self.pendingPath = nil
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let pendingPath = pendingPath {
            pendingPath.addPointSample(location: convertEventLocation(event.locationInWindow))
            view.needsDisplay = true
        }
    }

}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // empty
    }
    
    func draw(in view: MTKView) {
        let pendingPaths = pendingPath.map{ [$0] } ?? []
        renderer.render(in: view, paths: paths + pendingPaths, viewport: CGRect(origin: origin, size: view.bounds.size))
    }
    
    
}
