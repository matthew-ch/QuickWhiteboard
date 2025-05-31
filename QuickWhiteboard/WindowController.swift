//
//  WindowController.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

import Cocoa

final class WindowController: NSWindowController {
    
    static let identifier = "WindowController"
    
    static func createNewWindowController() -> Self {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateController(withIdentifier: Self.identifier) as! Self
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        window?.isMovableByWindowBackground = true
    }

    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        if sendType == nil, let pasteboardType = returnType, NSImage.imageTypes.contains(pasteboardType.rawValue) {
            return contentViewController
        }
        return super.validRequestor(forSendType: sendType, returnType: returnType)
    }
}

extension WindowController: NSWindowDelegate {
    func windowDidChangeScreen(_ notification: Notification) {
        (window?.contentViewController as? ViewController)?.onScreenChange()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if let viewController = window?.contentViewController as? ViewController, viewController.toolbarDataModel.isImportant {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = localizedString("This window is marked important.")
            alert.beginSheetModal(for: window!)
            return false
        }
        return true
    }
}
