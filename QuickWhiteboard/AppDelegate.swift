//
//  AppDelegate.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/24.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var windowControllers: [WindowController] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        newDocument(nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidClose(_:)), name: NSWindow.willCloseNotification, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        NSColorPanel.shared.close()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }


    @IBAction func newDocument(_ sender: Any?) {
        let windowController = WindowController.createNewWindowController()
        windowControllers.append(windowController)
        windowController.showWindow(nil)
    }
    
    @MainActor @objc func windowDidClose(_ sender: Notification) {
        let window = sender.object as! NSWindow
        if let windowController = window.windowController as? WindowController, let index = windowControllers.firstIndex(of: windowController) {
            windowControllers.remove(at: index)
        }
    }
}

