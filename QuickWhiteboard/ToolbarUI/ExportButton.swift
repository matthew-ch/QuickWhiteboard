//
//  ExportButton.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/4/8.
//
import SwiftUI

struct ExportButton: NSViewRepresentable {

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(
            image: NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)!,
            target: context.coordinator,
            action: #selector(ViewController.exportCanvas(_:))
        )
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return button
    }
    
    func updateNSView(_ nsView: NSButton, context: Context) {
    }
    
    typealias NSViewType = NSButton
}
