//
//  WindowController.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

import Cocoa

class WindowController: NSWindowController {

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
