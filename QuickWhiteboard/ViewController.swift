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
        
        let path = DrawingPath(color: .init(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0), strokeWidth: 2.0)
        path.addPointSample(location: .init(x: 100, y: 100))
        path.addPointSample(location: .init(x: 100, y: 200))
        path.addPointSample(location: .init(x: 300, y: 400))
        
        paths.append(path)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // empty
    }
    
    func draw(in view: MTKView) {
        renderer.render(in: view, paths: paths, viewport: CGRect(origin: origin, size: view.bounds.size))
    }
    
    
}
