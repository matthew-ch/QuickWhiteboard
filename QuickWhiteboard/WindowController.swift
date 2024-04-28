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

    @IBOutlet weak var toolbar: NSToolbar!

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func viewController() -> ViewController {
        self.contentViewController as! ViewController
    }

    @IBAction func onExport(_ sender: Any) {
        
    }
}
