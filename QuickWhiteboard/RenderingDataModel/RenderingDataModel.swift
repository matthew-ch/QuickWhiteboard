//
//  Model.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

import Foundation

@MainActor
protocol RenderItem: AnyObject, ToolEditingItem {
    var globalPosition: CGPoint { get set }
    var localBoundingRect: CGRect { get }
    var hidden: Bool { get set }
    var frozen: Bool { get set }
    var isOpaque: Bool { get }
    func distance(to globalLocation: CGPoint) -> Float
}

extension RenderItem {
    var boundingRect: CGRect {
        localBoundingRect.offsetBy(dx: globalPosition.x, dy: globalPosition.y)
    }
}

@MainActor
protocol CanMarkAsDirty: AnyObject {
    func markAsDirty() -> Void
}

@propertyWrapper
@MainActor
struct DirtyMarking<Value> {

    @available(*, unavailable)
    var wrappedValue: Value {
        get { fatalError("only works on instance properties of classes") }
        set { fatalError("only works on instance properties of classes") }
    }

    private var stored: Value

    init(wrappedValue: Value) {
        self.stored = wrappedValue
    }

    static subscript<EnclosingType: CanMarkAsDirty>(
        _enclosingInstance instance: EnclosingType,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingType, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingType, Self>
    ) -> Value {
        get {
            instance[keyPath: storageKeyPath].stored
        }
        set {
            instance[keyPath: storageKeyPath].stored = newValue
            instance.markAsDirty()
        }
    }
}

@MainActor
protocol HasGeneration: AnyObject {
    var generation: Int { get }
}

@propertyWrapper
@MainActor
struct OnDemand<EnclosingType: HasGeneration, Value> {

    @available(*, unavailable)
    var wrappedValue: Value {
        get { fatalError("only works on instance properties of classes") }
        set { fatalError("only works on instance properties of classes") }
    }

    static subscript(
        _enclosingInstance instance: EnclosingType,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingType, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingType, Self>
    ) -> Value {
        get {
            let builderKeyPath = instance[keyPath: storageKeyPath].builderKeyPath
            return instance[keyPath: storageKeyPath].updatedIfNeeded(generation: instance.generation) {
                instance[keyPath: builderKeyPath]
            }
        }
        set {
            fatalError("no setter supported")
        }
    }

    typealias BuilderKeyPath = KeyPath<EnclosingType, Value>

    private let builderKeyPath: BuilderKeyPath
    private let once: Bool
    private var cachedValue: Optional<Value> = nil
    private var generation = 0

    init(_ arg: BuilderKeyPath, once: Bool = false) {
        self.builderKeyPath = arg
        self.once = once
    }

    private mutating func updatedIfNeeded(generation: Int, valueFn: () -> Value) -> Value {
        if cachedValue == nil || !once && self.generation < generation {
            cachedValue = valueFn()
            self.generation = generation
        }
        return cachedValue!
    }
}
