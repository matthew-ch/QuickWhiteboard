//
//  WindowController.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

import Cocoa

extension NSToolbarItem.Identifier {
    static let appDebug = Self.init("app.debug")
    static let appExport = Self.init("app.export")
    static let appStrokeWidth = Self.init("app.strokeWidth")
    static let appColor = Self.init("app.color")
}

final class WindowController: NSWindowController {
    
    static let identifier = "WindowController"
    
    static func createNewWindowController() -> Self {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateController(withIdentifier: Self.identifier) as! Self
    }

    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet weak var swSlider: NSSlider!
    @IBOutlet weak var colorWell: NSColorWell!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        if #available(macOS 14.0, *) {
            colorWell.supportsAlpha = false
        }
    }
    
    private var viewController: ViewController! {
        self.contentViewController as? ViewController
    }

    @IBAction func onExport(_ sender: Any) {
        
    }
}

extension WindowController: NSWindowDelegate {
    func windowDidChangeScreen(_ notification: Notification) {
        window?.contentViewController?.view.needsDisplay = true
    }
}

extension WindowController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        var identifiers: [NSToolbarItem.Identifier] = [
            .space,
            .appStrokeWidth,
            .space,
            .appColor,
            .flexibleSpace,
        ]
#if DEBUG
        identifiers.append(contentsOf: [
            .appDebug,
            .space
        ])
#endif
        identifiers.append(contentsOf: [
            .appExport,
            .space,
        ])
        return identifiers
    }
}
