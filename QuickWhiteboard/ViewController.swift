//
//  ViewController.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/24.
//

import Cocoa
import MetalKit
import UniformTypeIdentifiers

class ViewController: NSViewController {
    
    private var items: [RenderItem] = []
    private var renderer: Renderer!
    private var origin: CGPoint = .zero
    private var pendingPath: DrawingPath?
    
    private var color: CGColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    private var strokeWidth = 2.0
    
    private var debug = false
    
    private lazy var destinationURL: URL = {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        return destinationURL
    }()
    
    private lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()

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
        
        view.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.addTrackingArea(.init(rect: view.bounds, options: [.inVisibleRect, .cursorUpdate, .activeInKeyWindow], owner: self))
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        for area in view.trackingAreas {
            view.removeTrackingArea(area)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: event handling

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
            items.append(pendingPath)
            self.pendingPath = nil
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let pendingPath = pendingPath {
            pendingPath.addPointSample(location: convertEventLocation(event.locationInWindow))
            view.needsDisplay = true
        }
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
    }
    
    @IBAction func toggleDebug(_ sender: Any) {
        debug.toggle()
        view.needsDisplay = true
    }
    
    func addImage(_ image: NSImage) {
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let imageItem = ImageRect(image: cgImage, boundingRect: .init(origin: origin, size: .init(width: cgImage.width, height: cgImage.height)))
            items.append(imageItem)
            view.needsDisplay = true
        }
    }
    
    private func handleFile(url: URL) {
        if let image = NSImage(contentsOf: url) {
            DispatchQueue.main.async {
                self.addImage(image)
            }
        }
    }
}

extension ViewController: NSDraggingDestination {
    func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSourceOperationMask.intersection([.copy])
    }
    
    func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self
        ]
        let acceptedTypes = [UTType.image.identifier]
        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: acceptedTypes
        ]
        sender.enumerateDraggingItems(for: nil, classes: supportedClasses, searchOptions: searchOptions) { draggingItem, _, _ in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                filePromiseReceiver.receivePromisedFiles(atDestination: self.destinationURL, operationQueue: self.workQueue) { fileUrl, error in
                    if error == nil {
                        self.handleFile(url: fileUrl)
                    }
                }
            case let fileURL as URL:
                self.handleFile(url: fileURL)
            default:
                break
            }
        }
        return true
    }
}

extension ViewController: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // empty
    }
    
    func draw(in view: MTKView) {
        let pendingPaths = pendingPath.map{ [$0] } ?? []
        renderer.render(in: view, items: items + pendingPaths, viewport: CGRect(origin: origin, size: view.bounds.size), debug: debug)
    }
    
    
}
