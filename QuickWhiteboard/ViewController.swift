//
//  ViewController.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/24.
//

import Cocoa
import MetalKit
import UniformTypeIdentifiers
import SwiftUI
import Combine

class ViewController: NSViewController {
    
    @IBOutlet weak var canvasView: CanvasView!
    @IBOutlet weak var toolbarContainerView: NSView!

    private var items: [any RenderItem] = []
    private var renderer: Renderer!
    private var center: CGPoint = .zero

    private var viewport: CGRect {
        CGRect(origin: .init(x: floor(center.x - canvasView.bounds.midX), y: floor(center.y - canvasView.bounds.midY)),
               size: canvasView.bounds.size)
    }

    private var nonHiddenItemsBoundingRect: CGRect {
        var rect = CGRect.zero
        for item in items {
            if item.hidden {
                continue
            }
            rect = rect.union(item.boundingRect)
        }
        return rect
    }

    private var gridItem = GridItem(boundingRect: .zero)

    private lazy var freehandTool = FreehandTool()
    private lazy var lineTool = LineTool()
    private lazy var rectangleTool = RectangleTool()
    private lazy var ellipseTool = EllipseTool()
    private lazy var eraserTool = EraserTool()
    private lazy var imageTool = ImageTool()
    private lazy var cursorTool = CursorTool()
    private lazy var noOpTool = NoOpTool()

    private var activeTool: any Tool {
        switch toolbarDataModel.activeToolIdentifier {
        case .freehand:
            freehandTool
        case .line:
            lineTool
        case .rectangle:
            rectangleTool
        case .ellipse:
            ellipseTool
        case .eraser:
            eraserTool
        case .image:
            imageTool
        case .cursor:
            cursorTool
        case .grid:
            noOpTool
        }
    }
    
    var isEditing: Bool {
        activeTool.editingItem != nil
    }

    private var isLeftMouseDown = false
    private var isRightMouseDown = false

    let toolbarDataModel = ToolbarDataModel(strokeWidth: 2.0, strokeColor: .init(x: 0.0, y: 0.0, z: 0.0, w: 1.0))

    private var cancellables: Set<AnyCancellable> = []

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
        let device = canvasView.preferredDevice ?? MTLCreateSystemDefaultDevice()!
        canvasView.device = device
        canvasView.framebufferOnly = false
        canvasView.colorPixelFormat = .rgba8Unorm
        renderer = Renderer(with: device, pixelFormat: canvasView.colorPixelFormat)
        renderer.updateOnScreenDrawableSize(canvasView.drawableSize)
        canvasView.delegate = self
        canvasView.isPaused = true
        canvasView.enableSetNeedsDisplay = true
        
        canvasView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        canvasView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        
        let toolbarView = NSHostingView(rootView: ToolbarControls(dataModel: toolbarDataModel, delegate: self))
        toolbarView.autoresizingMask = [.width]
        toolbarView.frame = toolbarContainerView.bounds
        toolbarView.translatesAutoresizingMaskIntoConstraints = true
        toolbarContainerView.addSubview(toolbarView)

        presets.$strokePresets.sink { [weak self] strokePresets in
            self?.toolbarDataModel.strokePresets = strokePresets
        }.store(in: &cancellables)

        toolbarDataModel.$isGridVisible.map({_ in }).merge(with: toolbarDataModel.$gridColor.map({_ in }), toolbarDataModel.$gridSpacing.map({_ in })).sink { [weak self] _ in
            self?.setNeedsDisplay()
        }.store(in: &cancellables)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        canvasView.addTrackingArea(.init(rect: canvasView.bounds, options: [.inVisibleRect, .cursorUpdate, .activeInKeyWindow], owner: canvasView))
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        for area in canvasView.trackingAreas {
            canvasView.removeTrackingArea(area)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func renderImage() -> NSImage {
        let size = canvasView.drawableSize
        let texture = renderer.renderOffscreen(of: size, items: items, viewport: viewport)
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerRow = width * 4
        let totalBytes = bytesPerRow * height
        let data = UnsafeMutableRawPointer.allocate(byteCount: totalBytes, alignment: 4)
        
        texture.getBytes(data, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        let dataProvider = CGDataProvider(data: NSData(bytesNoCopy: data, length: totalBytes, freeWhenDone: true))!
        
        let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!

        let image = NSImage(cgImage: cgImage, size: .zero)
        return image
    }
    
    // MARK: event handling

    func onScreenChange() {
        canvasView.needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        guard !isLeftMouseDown && !isRightMouseDown else {
            return
        }
        if event.specialKey == .backspace || event.specialKey == .delete {
            activeTool.handleDelete(host: self)
            return
        }
        if event.specialKey == .carriageReturn && !event.isARepeat {
            commitActiveTool()
            return
        }
        guard !isEditing, event.modifierFlags.intersection([.shift, .control, .option]).isEmpty, !event.isARepeat else {
            return
        }
        guard let chars = event.charactersIgnoringModifiers?.lowercased() else {
            return
        }
        for toolIdentifier in ToolIdentifier.allCases {
            if toolIdentifier.shortcutKey.lowercased() == chars {
                onClickTool(identifier: toolIdentifier)
                if mouseIsInsideCanvas() {
                    activeTool.setCursor(host: self)
                }
                break
            }
        }
    }

    func canvasSetCursor(with event: NSEvent) {
        if isRightMouseDown {
            NSCursor.closedHand.set()
        } else {
            activeTool.setCursor(host: self)
        }
    }

    func canvasViewScrollWheel(with event: NSEvent) {
        let factor = event.hasPreciseScrollingDeltas ? 1.0 : 5.0
        center.x -= event.scrollingDeltaX * factor
        center.y += event.scrollingDeltaY * factor
        center = center.alignedToSubpixel
        setNeedsDisplay()
    }
    
    private func convertEventLocation(_ location: NSPoint) -> CGPoint {
        let point = canvasView.convert(location, from: nil)
        return CGPoint(x: point.x - canvasView.bounds.midX + center.x, y: point.y - canvasView.bounds.midY + center.y).alignedToSubpixel
    }
    
    func canvasViewMouseDown(with event: NSEvent) {
        if isRightMouseDown {
            return
        }
        isLeftMouseDown = true
        activeTool.mouseDown(with: event,
                             location: convertEventLocation(event.locationInWindow),
                             host: self)
    }

    func canvasViewMouseDragged(with event: NSEvent) {
        if isLeftMouseDown {
            activeTool.mouseDragged(with: event,
                                    location: convertEventLocation(event.locationInWindow),
                                    host: self)
        }
    }

    func canvasViewMouseUp(with event: NSEvent) {
        if isLeftMouseDown {
            activeTool.mouseUp(with: event,
                               location: convertEventLocation(event.locationInWindow),
                               host: self)
        }
        isLeftMouseDown = false
    }

    func canvasRightMouseDown(with event: NSEvent) {
        if isLeftMouseDown {
            return
        }
        isRightMouseDown = true
        canvasSetCursor(with: event)
    }

    func canvasRightMouseDragged(with event: NSEvent) {
        if isRightMouseDown {
            center.x -= event.deltaX
            center.y += event.deltaY
            center = center.alignedToSubpixel
            setNeedsDisplay()
        }
    }

    func canvasRightMouseUp(with event: NSEvent) {
        isRightMouseDown = false
        if mouseIsInsideCanvas() {
            canvasSetCursor(with: event)
        }
    }

    @IBAction func paste(_ sender: Any) {
        readImage(from: NSPasteboard.general)
    }
    
    @IBAction func copy(_ sender: Any) {
        let image = renderImage()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    @IBAction func freeze(_ sender: Any) {
        let frozenItems = items.filter { item in
            !item.hidden && !item.frozen
        }
        frozenItems.forEach { item in
            item.frozen = true
        }
        undoManager?.registerUndo(withTarget: self, selector: #selector(unfreeze(_:)), object: frozenItems as NSArray)
    }

    @IBAction func clearStrokes(_ sender: Any) {
        let erasedItems = ErasedItems()
        for item in items {
            if item.frozen || item.hidden {
                continue
            }
            erasedItems.selected.append(item)
        }
        if (!erasedItems.selected.isEmpty) {
            eraseItems(erasedItems)
        }
    }

    @IBAction func clearAll(_: Any) {
        let removedItems = items as NSArray
        items = []
        undoManager?.registerUndo(withTarget: self, selector: #selector(restoreClearedItems(_:)), object: removedItems)
        setNeedsDisplay()
    }

    @IBAction func toggleGrid(_ sender: Any) {
        toolbarDataModel.isGridVisible.toggle()
    }

    @IBAction func toUpmost(_ sender: Any) {
        let viewport = self.viewport
        let rect = nonHiddenItemsBoundingRect.insetBy(dx: -20.0, dy: -20.0)
        if rect.maxY > viewport.maxY {
            center.y = rect.maxY - viewport.height / 2.0
            center = center.alignedToSubpixel
            setNeedsDisplay()
        } else {
            NSSound.beep()
        }
    }

    @IBAction func toBottommost(_ sender: Any) {
        let viewport = self.viewport
        let rect = nonHiddenItemsBoundingRect.insetBy(dx: -20.0, dy: -20.0)
        if rect.minY < viewport.minY {
            center.y = rect.minY + viewport.height / 2.0
            center = center.alignedToSubpixel
            setNeedsDisplay()
        } else {
            NSSound.beep()
        }
    }

    @IBAction func toLeftmmost(_ sender: Any) {
        let viewport = self.viewport
        let rect = nonHiddenItemsBoundingRect.insetBy(dx: -20.0, dy: -20.0)
        if rect.minX < viewport.minX {
            center.x = rect.minX + viewport.width / 2.0
            center = center.alignedToSubpixel
            setNeedsDisplay()
        } else {
            NSSound.beep()
        }
    }

    @IBAction func toRightmmost(_ sender: Any) {
        let viewport = self.viewport
        let rect = nonHiddenItemsBoundingRect.insetBy(dx: -20.0, dy: -20.0)
        if rect.maxX > viewport.maxX {
            center.x = rect.maxX - viewport.width / 2.0
            center = center.alignedToSubpixel
            setNeedsDisplay()
        } else {
            NSSound.beep()
        }
    }

    @objc func unfreeze(_ frozenItems: Any) {
        let frozenItems = frozenItems as! NSArray as! Array<any RenderItem>
        frozenItems.forEach { item in
            item.frozen = false
        }
        undoManager?.registerUndo(withTarget: self, selector: #selector(freeze(_:)), object: nil)
    }

    @objc func restoreClearedItems(_ removedItems: Any) {
        items = removedItems as! NSArray as! Array<any RenderItem>
        undoManager?.registerUndo(withTarget: self, selector: #selector(clearAll(_:)), object: nil)
        setNeedsDisplay()
    }

    @objc func addItem(_ item: Any) {
        items.append(item as! RenderItem)
        undoManager?.registerUndo(withTarget: self, selector: #selector(removeLastItem(_:)), object: nil)
        setNeedsDisplay()
    }
    
    @objc func removeLastItem(_: Any?) {
        if let item = items.popLast() {
            undoManager?.registerUndo(withTarget: self, selector: #selector(addItem(_:)), object: item)
            setNeedsDisplay()
        }
    }
    
    @objc func eraseItems(_ item: Any) {
        (item as! ErasedItems).erase()
        undoManager?.registerUndo(withTarget: self, selector: #selector(restoreErasedItems(_:)), object: item)
        setNeedsDisplay()
    }
    
    @objc func restoreErasedItems(_ item: Any) {
        (item as! ErasedItems).restore()
        undoManager?.registerUndo(withTarget: self, selector: #selector(eraseItems(_:)), object: item)
        setNeedsDisplay()
    }

    @objc func moveItems(_ item: Any) {
        (item as! MovedItems).apply()
        undoManager?.registerUndo(withTarget: self, selector: #selector(undoMoveItems(_:)), object: item)
        setNeedsDisplay()
    }

    @objc func undoMoveItems(_ item: Any) {
        (item as! MovedItems).revert()
        undoManager?.registerUndo(withTarget: self, selector: #selector(moveItems(_:)), object: item)
        setNeedsDisplay()
    }

    // MARK: utility methods
    
    private func mouseIsInsideCanvas() -> Bool {
        let mousePosition = view.window!.mouseLocationOutsideOfEventStream
        let location = canvasView.convert(mousePosition, from: nil)
        return canvasView.bounds.contains(location)
    }

    private func addImage(_ image: NSImage) {
        commitActiveTool()
        let size = image.size
        let scale = image.representations.first is NSPDFImageRep ? 2.0 : 1.0
        let cgContext = CGContext(data: nil, width: Int(size.width * scale), height: Int(size.height * scale), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        var rect = CGRect(origin: .zero, size: .init(width: size.width * scale, height: size.height * scale))
        if let cgImage = image.cgImage(forProposedRect: &rect, context: NSGraphicsContext(cgContext: cgContext, flipped: false), hints: nil) {
            let imageCenter = CGPoint(x: viewport.midX, y: viewport.midY).alignedToSubpixel
            let imageItem = ImageItem(image: cgImage, position: imageCenter, size: size.float2)
            imageTool.setImageItem(item: imageItem, host: self)
            toolbarDataModel.activeToolIdentifier = .image
        }
    }

    nonisolated
    private func handleFile(url: URL) {
        Task.detached(priority: .high, operation: {
            if let image = NSImage(contentsOf: url) {
                await self.addImage(image)
            }
        })
    }
    
    func viewHasSetNewSize(_ newSize: CGSize) {
    }
    
    private func canReadImage(from pasteboard: NSPasteboard) -> Bool {
        pasteboard.canReadObject(forClasses: [NSImage.self], options: [.urlReadingContentsConformToTypes: [UTType.image.identifier]])
    }
    
    @discardableResult
    private func readImage(from pasteboard: NSPasteboard) -> Bool {
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: [.urlReadingContentsConformToTypes: [UTType.image.identifier]]), let image = images.first as? NSImage {
            addImage(image)
            return true
        }
        return false
    }
}

// MARK: ToolDelegate
extension ViewController: ToolHost {
    var renderItems: [any RenderItem] {
        items
    }
    
    func setDefaultTool() {
        toolbarDataModel.activeToolIdentifier = .freehand
    }
    
    func setNeedsDisplay() {
        canvasView.needsDisplay = true
    }
    
    func commit(item: any ToolEditingItem) {
        if let item = item as? RenderItem {
            addItem(item)
        } else if let item = item as? ErasedItems {
            eraseItems(item)
        } else if let item = item as? MovedItems {
            moveItems(item)
        }
    }
}

// MARK: ToolbarDelegate
extension ViewController: ToolbarDelegate {

    func toggleDebug() {
        debug.toggle()
        setNeedsDisplay()
    }
    
    @objc
    func exportCanvas(_ sender: NSButton) {
        let image = renderImage()
        NSSharingServicePicker(items: [image]).show(relativeTo: .zero, of: sender, preferredEdge: .minY)
    }

    func commitActiveTool() {
        activeTool.commit(to: self)
    }

    func addStrokePreset() {
        presets.addStrokePreset(StrokePreset(width: toolbarDataModel.strokeWidth, color: toolbarDataModel.strokeColor))
    }

    func removeStrokePreset(preset: StrokePreset) {
        presets.removeStrokePreset(preset)
    }

    func onClickTool(identifier: ToolIdentifier) {
        commitActiveTool()
        if identifier == .image {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
            openPanel.allowsMultipleSelection = false
            openPanel.resolvesAliases = true
            openPanel.allowedContentTypes = [UTType.image]
            openPanel.beginSheetModal(for: view.window!) { [weak self] res in
                guard res == .OK else {
                    return
                }
                if let url = openPanel.url {
                    self?.handleFile(url: url)
                }
            }
        } else {
            toolbarDataModel.activeToolIdentifier = identifier
        }
    }
}

// MARK: NSServicesMenuRequestor
extension ViewController: @preconcurrency NSServicesMenuRequestor {
    func readSelection(from pboard: NSPasteboard) -> Bool {
        guard canReadImage(from: pboard) else {
            return false
        }
        return readImage(from: pboard)
    }
}

// MARK: NSMenuItemValidation
extension ViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(paste(_:)) {
            return !isEditing && canReadImage(from: NSPasteboard.general)
        }
        if menuItem.action == #selector(copy(_:)) {
            return !isEditing && !items.isEmpty
        }
        if menuItem.action == #selector(clearStrokes(_:)) {
            return !isEditing && !items.isEmpty
        }
        if menuItem.action == #selector(clearAll(_:)) {
            return !isEditing && !items.isEmpty
        }
        if menuItem.action == #selector(freeze(_:)) {
            return !isEditing && !items.isEmpty
        }
        if menuItem.action == #selector(toggleGrid(_:)) {
            menuItem.state = toolbarDataModel.isGridVisible ? .on : .off
        }
        return true
    }
}

// MARK: NSDraggingDestination
extension ViewController: NSDraggingDestination {
    func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSourceOperationMask.intersection([.copy])
    }
    
    func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self
        ]
        let acceptedTypes = NSImage.imageTypes
        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: acceptedTypes
        ]
        sender.enumerateDraggingItems(for: nil, classes: supportedClasses, searchOptions: searchOptions) { draggingItem, _, stop in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                filePromiseReceiver.receivePromisedFiles(atDestination: self.destinationURL, operationQueue: self.workQueue) { @Sendable fileUrl, error in
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

// MARK: MTKViewDelegate
extension ViewController: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.updateOnScreenDrawableSize(size)
    }
    
    func draw(in view: MTKView) {
        let viewport = self.viewport
        var renderItems: [any RenderItem] = []
        if toolbarDataModel.isGridVisible {
            gridItem.localBoundingRect = viewport
            gridItem.color = toolbarDataModel.gridColor
            gridItem.spacing = toolbarDataModel.gridSpacing
            renderItems.append(gridItem)
        }
        renderItems.append(contentsOf: items)
        if let activeItem = activeTool.editingItem as? RenderItem {
            renderItems.append(activeItem)
        }
        renderer.render(in: view, items: renderItems, viewport: viewport, debug: debug)
    }
    
}
