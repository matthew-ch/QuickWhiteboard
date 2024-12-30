//
//  Presets.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/12/30.
//

import Foundation
import Combine
import AppKit

class StrokePreset: NSObject, NSCoding, NSSecureCoding, Identifiable {
    static let supportsSecureCoding: Bool = true

    func encode(with coder: NSCoder) {
        coder.encode(Double(width), forKey: "width")
        coder.encode(color, forKey: "color")
    }
    
    required init?(coder: NSCoder) {
        self.width = coder.decodeDouble(forKey: "width")
        guard let color = coder.decodeObject(of: NSColor.self, forKey: "color") else {
            return nil
        }
        self.color = color
        self.id = UUID()
    }

    init(width: CGFloat, color: NSColor) {
        self.width = width
        self.color = color
        self.id = UUID()
        super.init()
    }

    let width: CGFloat
    let color: NSColor
    let id: UUID
}

class Presets: NSObject, ObservableObject {
    static let storageURL: URL = {
        let appSupportURL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let appDirURL = appSupportURL.appendingPathComponent("QuickWhiteboard", isDirectory: true)
        try! FileManager.default.createDirectory(at: appDirURL, withIntermediateDirectories: true)
        return appDirURL.appendingPathComponent("presets", isDirectory: false)
    }()

    @Published var strokePresets: [StrokePreset] = []

    private(set) var hasChanged = false

    func addStrokePreset(_ preset: StrokePreset) {
        strokePresets.append(preset)
        hasChanged = true
    }

    func removeStrokePreset(_ preset: StrokePreset) {
        if let index = strokePresets.firstIndex(where: { item in
            item.id == preset.id
        }) {
            strokePresets.remove(at: index)
            hasChanged = true
        }
    }

    func save() {
        guard hasChanged else {
            return
        }
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(strokePresets as NSArray, forKey: "stroke")
        archiver.finishEncoding()
        do {
            try archiver.encodedData.write(to: Self.storageURL, options: .atomic)
        } catch let error {
            print("presets save error", error)
        }
    }

    func load() {
        do {
            let data = try Data(contentsOf: Self.storageURL, options: [])
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.decodingFailurePolicy = .raiseException
            defer {
                unarchiver.finishDecoding()
            }
            let s = unarchiver.decodeObject(of: [NSArray.self, StrokePreset.self], forKey: "stroke")
            guard let strokePresets = s as? NSArray as? [StrokePreset] else {
                return
            }
            self.strokePresets = strokePresets
        } catch let error {
            print("presets load error", error)
        }
    }
}

@MainActor let presets = Presets()
