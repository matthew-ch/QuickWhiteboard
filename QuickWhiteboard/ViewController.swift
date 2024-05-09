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
    
    private var windowController: WindowController! {
        self.view.window!.windowController as? WindowController
    }
    
    private var color: CGColor {
        return windowController.colorWell.color.usingColorSpace(.sRGB)!.cgColor
    }

    private var strokeWidth: CGFloat {
        return CGFloat(windowController.swSlider.integerValue)
    }
    
    private var debug = false
    private var previousViewSize: CGSize = .zero
    
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
    
    private func renderImage() -> NSImage {
        let size = (self.view as! MTKView).drawableSize
        let texture = renderer.renderOffscreen(of: size, items: items, viewport: CGRect(origin: origin, size: view.bounds.size))
        let ciImage = CIImage(mtlTexture: texture, options: [.colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])!.transformed(by: .init(scaleX: 1, y: -1))
        let context = CIContext()
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent, format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB))!
        let image = NSImage(cgImage: cgImage, size: size)
        return image
    }
    
    // MARK: event handling

    override func scrollWheel(with event: NSEvent) {
        let factor = event.hasPreciseScrollingDeltas ? 1.0 : 5.0
        origin.x -= event.scrollingDeltaX * factor
        origin.y += event.scrollingDeltaY * factor
        origin = origin.rounded
        view.needsDisplay = true
    }
    
    private func convertEventLocation(_ location: NSPoint) -> CGPoint {
        let point = view.convert(location, from: nil)
        return CGPoint(x: point.x + origin.x, y: point.y + origin.y).rounded
    }
    
    override func mouseDown(with event: NSEvent) {
        pendingPath = DrawingPath(color: color, strokeWidth: strokeWidth)
        pendingPath?.addPointSample(location: convertEventLocation(event.locationInWindow))
    }
    
    override func mouseUp(with event: NSEvent) {
        if let pendingPath = pendingPath {
            items.append(pendingPath)
            view.needsDisplay = true
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
    
    @IBAction func paste(_ sender: Any) {
        if let images = NSPasteboard.general.readObjects(forClasses: [NSImage.self]), let image = images.first as? NSImage {
            addImage(image)
        }
    }
    
    @IBAction func copy(_ sender: Any) {
        let image = renderImage()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    private func addImage(_ image: NSImage) {
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let imageOrigin = CGPoint(x: origin.x + view.bounds.midX - CGFloat(cgImage.width) / 2.0, y: origin.y + view.bounds.midY - CGFloat(cgImage.height) / 2.0).rounded
            let imageItem = ImageRect(image: cgImage, boundingRect: .init(origin: imageOrigin, size: .init(width: cgImage.width, height: cgImage.height)))
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
    
    func viewHasSetNewSize(_ newSize: CGSize) {
        if previousViewSize != .zero {
            origin.x -= (newSize.width - previousViewSize.width) / 2.0
            origin.y -= (newSize.height - previousViewSize.height) / 2.0
            origin = origin.rounded
        }
        previousViewSize = newSize
    }
    
    func exportCanvas(_ sender: NSToolbarItem) {
        let image = renderImage()
        let toolbarButton = sender.value(forKey: "_view") as! NSView
        NSSharingServicePicker(items: [image]).show(relativeTo: .zero, of: toolbarButton, preferredEdge: .minY)
    }
}

extension ViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(paste(_:)) {
            return NSPasteboard.general.canReadObject(forClasses: [NSImage.self])
        }
        return true
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
        sender.enumerateDraggingItems(for: nil, classes: supportedClasses, searchOptions: searchOptions) { draggingItem, _, stop in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                filePromiseReceiver.receivePromisedFiles(atDestination: self.destinationURL, operationQueue: self.workQueue) { fileUrl, error in
                    if error == nil {
                        self.handleFile(url: fileUrl)
                    }
                }
                stop.pointee = true
            case let fileURL as URL:
                self.handleFile(url: fileURL)
                stop.pointee = true
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
