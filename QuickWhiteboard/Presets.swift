//
//  Presets.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/12/30.
//

import Foundation
import Combine
import AppKit

struct StrokePreset: Codable, Identifiable {
    let width: CGFloat
    let color: SIMD4<Float>
    let id = UUID()

    enum CodingKeys: String, CodingKey {
        case width
        case color
    }
}

struct PresetsContainer: Codable {
    let stroke: [StrokePreset]
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
        let presetsContainer = PresetsContainer(stroke: strokePresets)
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(presetsContainer)
            try data.write(to: Self.storageURL, options: .atomic)
        } catch let error {
            print("presets save error", error)
        }
    }

    func load() {
        do {
            let data = try Data(contentsOf: Self.storageURL, options: [])
            let decoder = JSONDecoder()
            let presetsContainer = try decoder.decode(PresetsContainer.self, from: data)
            self.strokePresets = presetsContainer.stroke
        } catch let error {
            print("presets load error", error)
        }
    }
}

@MainActor let presets = Presets()
