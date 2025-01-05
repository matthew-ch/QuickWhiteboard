//
//  Model.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

import Foundation
import CoreGraphics
import Metal
import MetalKit
import simd

@MainActor
protocol RenderItem: AnyObject, ToolEditingItem {
    var boundingRect: CGRect { get }
    var hidden: Bool { get set }
}

struct PointSample {
    let location: SIMD2<Float>
}

final class ErasedItems: ToolEditingItem {
    var selected: [any RenderItem] = []
    
    func erase() {
        for item in selected {
            item.hidden = true
        }
    }
    
    func restore() {
        for item in selected {
            item.hidden = false
        }
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

class DrawingItem: RenderItem, CanMarkAsDirty, HasGeneration {

    var points: [PointSample] {
        []
    }
    var boundingRect: CGRect {
        CGRect(origin: .init(x: CGFloat.infinity, y: CGFloat.infinity), size: .zero)
    }
    var isClosedPath: Bool {
        false
    }

    var hidden: Bool = false

    let strokeColor: SIMD4<Float>
    let strokeWidth: Float

    private(set) var generation = 1

    @OnDemand(\DrawingItem.generateVertexBuffer)
    private var vertexBuffer: (any MTLBuffer)

    init(strokeColor: SIMD4<Float>, strokeWidth: CGFloat) {
        self.strokeColor = strokeColor
        self.strokeWidth = Float(strokeWidth)
    }

    func generateTriangles(point: PointSample, previousPoint: PointSample?, nextPoint: PointSample?) -> [SIMD2<Float>] {
        let location = point.location
        let previousLocation = previousPoint?.location
        let nextLocation = nextPoint?.location

        let pointTriangleCount = max(Int(ceilf(Float.pi * strokeWidth / 2.0)), 4)
        var points: [SIMD2<Float>] = divideUnitCircle(count: pointTriangleCount)
        points.append(points[0])
        let radius = strokeWidth / 2.0
        var visibleIndices = Array(0..<pointTriangleCount)

        var result: [SIMD2<Float>] = []

        if let nextLocation {
            let v = normalize(location - nextLocation)
            visibleIndices = visibleIndices.filter { i in
                simd_dot(points[i], v) > 0 || simd_dot(points[i + 1], v) > 0
            }
        }

        if let previousLocation {
            let v = normalize(location - previousLocation)
            let u = SIMD2<Float>(-v.y, v.x)
            let p0 = previousLocation + u * radius
            let p1 = previousLocation - u * radius
            let p2 = location + u * radius
            let p3 = location - u * radius
            result.append(p0)
            result.append(p1)
            result.append(p2)
            result.append(p2)
            result.append(p1)
            result.append(p3)

            visibleIndices = visibleIndices.filter { i in
                simd_dot(points[i], v) > 0 || simd_dot(points[i + 1], v) > 0
            }
        }

        for i in visibleIndices {
            result.append(location)
            result.append(points[i] * radius + location)
            result.append(points[i + 1] * radius + location)
        }
        return result
    }

    func generateVertexes(points: [PointSample]) -> [SIMD2<Float>] {
        var result: [SIMD2<Float>] = []
        for i in 0..<points.count {
            let previousPoint = i == 0 ? (isClosedPath ? points.last : nil) : points[i - 1]
            let nextPoint = i + 1 < points.count ? points[i + 1] : (isClosedPath ? points.first : nil)
            result.append(contentsOf: generateTriangles(point: points[i], previousPoint: previousPoint, nextPoint: nextPoint))
        }
        return result
    }

    private var device: (any MTLDevice)?

    private var generateVertexBuffer: any MTLBuffer {
        let vertexes = generateVertexes(points: points)
        return device!.makeBuffer(bytes: vertexes, length: MemoryLayout<SIMD2<Float>>.size * max(vertexes.count, 1))!
    }

    func upload(to device: MTLDevice) -> (vetexBuffer: any MTLBuffer, vertexCount: Int) {
        self.device = device
        return (vertexBuffer, vertexBuffer.length / MemoryLayout<SIMD2<Float>>.size)
    }

    final func markAsDirty() {
        generation += 1
    }

    func distanceToPath(from location: CGPoint) -> Float {
        var previousPoint = isClosedPath ? points.last! : points[0]
        var minDistance = Float.infinity
        for point in points {
            let d = distanceFromPointToLineSegment(point: location.float2, segmentPoints: previousPoint.location, point.location)
            previousPoint = point
            minDistance = min(minDistance, d)
        }
        return minDistance
    }
}

final class FreehandItem: DrawingItem {

    @DirtyMarking
    private var _points: [PointSample] = []

    override var points: [PointSample] {
        _points
    }

    @OnDemand(\FreehandItem.resolvedBoundingRect)
    private var _boundingRect: CGRect
    override var boundingRect: CGRect {
        _boundingRect
    }

    private var resolvedBoundingRect: CGRect {
        assert(!points.isEmpty)
        var minxy = SIMD2<Float>(x: Float.infinity, y: Float.infinity)
        var maxxy = SIMD2<Float>(x: -Float.infinity, y: -Float.infinity)
        for point in points {
            minxy = simd_min(minxy, point.location - strokeWidth)
            maxxy = simd_max(maxxy, point.location + strokeWidth)
        }
        return CGRect(origin: .from(minxy), size: .from(maxxy - minxy))
    }

    func addPointSample(location: CGPoint) {
        _points.append(PointSample(location: location.float2))
    }
}

final class LineItem: DrawingItem {

    override var points: [PointSample] {
        if from == to {
            return [PointSample(location: from)]
        } else {
            let to = endPoint
            if isCenterMode {
                return [
                    PointSample(location: from * 2.0 - to),
                    PointSample(location: to),
                ]
            } else {
                return [
                    PointSample(location: from),
                    PointSample(location: to),
                ]
            }
        }
    }

    @OnDemand(\LineItem.resolvedEndPoint)
    private var endPoint: SIMD2<Float>

    @OnDemand(\LineItem.resolvedBoundingRect)
    private var _boundingRect: CGRect
    override var boundingRect: CGRect {
        _boundingRect
    }

    @DirtyMarking
    var from: SIMD2<Float> = .zero

    @DirtyMarking
    var to: SIMD2<Float> = .zero

    @DirtyMarking
    var isCenterMode = false

    @DirtyMarking
    var isAligning = false

    static let dirXs = SIMD8<Float>(arrayLiteral: 0.0, halfOfSqrt2, 1.0, halfOfSqrt2, 0.0, -halfOfSqrt2, -1.0, -halfOfSqrt2)
    static let dirYs = SIMD8<Float>(arrayLiteral: 1.0, halfOfSqrt2, 0.0, -halfOfSqrt2, -1.0, -halfOfSqrt2, 0.0, halfOfSqrt2)

    private var resolvedBoundingRect: CGRect {
        let to = endPoint
        if isCenterMode {
            let halfDimens = simd_abs(to - from) + strokeWidth / 2.0
            return CGRect(origin: .from(from - halfDimens), size: .from(halfDimens * 2.0))
        } else {
            let center = (from + to) / 2.0
            let dimens = simd_abs(from - to) + strokeWidth
            return CGRect(origin: .from(center - dimens / 2.0), size: .from(dimens))
        }
    }

    private var resolvedEndPoint: SIMD2<Float> {
        if isAligning {
            let v = to - from
            let dots = Self.dirXs * v.x + Self.dirYs * v.y
            var maxIndex = 0
            var maxValue = dots[0]
            for index in 1..<8 {
                if dots[index] > maxValue {
                    maxValue = dots[index]
                    maxIndex = index
                }
            }
            let u = SIMD2<Float>(Self.dirXs[maxIndex], Self.dirYs[maxIndex]) * maxValue
            return from + u
        }
        return to
    }
}

final class RectangleItem: DrawingItem {

    @OnDemand(\RectangleItem.resolvedPoints)
    private var _points: [PointSample]
    override var points: [PointSample] {
        _points
    }

    @OnDemand(\RectangleItem.resolvedBoundingRect)
    private var _boundingRect: CGRect
    override var boundingRect: CGRect {
        _boundingRect
    }

    override var isClosedPath: Bool {
        return _points.count == 4
    }

    @OnDemand(\RectangleItem.resolvedEndPoint)
    private var endPoint: SIMD2<Float>

    @DirtyMarking
    var from: SIMD2<Float> = .zero

    @DirtyMarking
    var to: SIMD2<Float> = .zero

    @DirtyMarking
    var isCenterMode = false

    @DirtyMarking
    var isSquare = false

    private var resolvedBoundingRect: CGRect {
        let to = endPoint
        if isCenterMode {
            let center = from
            let halfDimens = simd_abs(to - from) + strokeWidth / 2.0
            return CGRect(origin: .from(center - halfDimens), size: .from(halfDimens * 2.0))
        } else {
            let center = (from + to) / 2.0
            let dimens = simd_abs(from - to) + strokeWidth
            return CGRect(origin: .from(center - dimens / 2.0), size: .from(dimens))
        }
    }

    private var resolvedEndPoint: SIMD2<Float> {
        if isSquare {
            let diff = to - from
            let length = abs(diff).max()
            return .init(x: from.x + (diff.x >= 0 ? length : -length), y: from.y + (diff.y >= 0 ? length : -length))
        }
        return to
    }

    private var resolvedPoints: [PointSample] {
        if from == to {
            return [PointSample(location: from)]
        } else {
            let to = endPoint
            let from: SIMD2<Float>
            if isCenterMode {
                from = self.from * 2.0 - to
            } else {
                from = self.from
            }
            if to.x == from.x || to.y == from.y {
                return [
                    PointSample(location: from),
                    PointSample(location: to),
                ]
            }
            return [
                PointSample(location: from),
                PointSample(location: .init(x: from.x, y: to.y)),
                PointSample(location: to),
                PointSample(location: .init(x: to.x, y: from.y)),
            ]
        }
    }
}

final class EllipseItem: DrawingItem {

    @OnDemand(\EllipseItem.resolvedPoints)
    private var _points: [PointSample]
    override var points: [PointSample] {
        _points
    }

    @OnDemand(\EllipseItem.resolvedBoundingRect)
    private var _boundingRect: CGRect
    override var boundingRect: CGRect {
        _boundingRect
    }

    override var isClosedPath: Bool {
        return _points.count > 2
    }

    @DirtyMarking
    var from: SIMD2<Float> = .zero

    @DirtyMarking
    var to: SIMD2<Float> = .zero

    @DirtyMarking
    var isCircle = false

    @DirtyMarking
    var isCenterMode = false

    private func calcCenterRxRy() -> (SIMD2<Float>, Float, Float) {
        let center: SIMD2<Float>
        if isCircle {
            let r: Float
            if isCenterMode {
                center = from
                r = simd_abs(to - center).max()
            } else {
                let d = simd_abs(to - from).max()
                r = d / 2.0
                center = from + .init(x: to.x >= from .x ? r : -r, y: to.y >= from.y ? r: -r)
            }
            return (center, r, r)
        } else {
            if isCenterMode {
                center = from
            } else {
                center = (from + to) / 2.0
            }
            let uv = to - center
            let rx = abs(uv.x)
            let ry = abs(uv.y)
            return (center, rx, ry)
        }
    }

    private var resolvedBoundingRect: CGRect {
        let (center, rx, ry) = calcCenterRxRy()
        let rs = SIMD2<Float>(x: rx + strokeWidth / 2.0, y: ry + strokeWidth / 2.0)
        return CGRect(origin: .from(center - rs), size: .from(rs * 2.0))
    }

    private var resolvedPoints: [PointSample] {
        if from == to {
            return [PointSample(location: from)]
        }
        let (origin, rx, ry) = calcCenterRxRy()
        if rx == 0.0 || ry == 0.0 {
            return [
                PointSample(location: origin - .init(x: rx, y: ry)),
                PointSample(location: origin + .init(x: rx, y: ry))
            ]
        }
        var points: [SIMD2<Float>] = []
        var theta: Float = 0.0
        let rxsqr = rx * rx
        let rysqr = ry * ry
        let pi_2 = Float.pi / 2.0
        while theta < pi_2 {
            let ct = cos(theta)
            let st = sin(theta)
            points.append(.init(x: rx * ct, y: ry * st))
            let d = sqrtf(rxsqr * st * st + rysqr * ct * ct)
            theta += min(4.0 / d, pi_2 / 16.0)
        }
        points.append(.init(x: 0.0, y: ry))
        for i in (0..<points.count - 1).reversed() {
            var p = points[i]
            p.x = -p.x
            points.append(p)
        }
        for i in (1..<points.count - 1).reversed() {
            var p = points[i]
            p.y = -p.y
            points.append(p)
        }
        return points.map { PointSample(location: $0 + origin) }
    }
}

final class ImageItem: RenderItem, CanMarkAsDirty, HasGeneration {
    private(set) var image: CGImage

    @DirtyMarking
    var center: SIMD2<Float>
    let size: SIMD2<Float>

    @DirtyMarking
    var scale: Float = 1.0

    @DirtyMarking
    var rotation: Float = 0.0

    @OnDemand(\ImageItem.resolvedBoundingRect)
    private var _boundingRect: CGRect
    var boundingRect: CGRect {
        _boundingRect
    }

    var hidden: Bool = false

    private var device: (any MTLDevice)?

    @OnDemand(\ImageItem.resolvedTexture, once: true)
    private var texture: (any MTLTexture)

    @OnDemand(\ImageItem.resolvedVertexBuffer)
    private var vertexBuffer: (any MTLBuffer)

    @OnDemand(\ImageItem.resolvedUVBuffer, once: true)
    private var uvBuffer: (any MTLBuffer)
    
    static var textureLoader: MTKTextureLoader!
    static let uvs: [SIMD2<Float>] = [
        .init(0.0, 1.0),
        .init(1.0, 0.0),
        .init(0.0, 0.0),
        .init(1.0, 0.0),
        .init(0.0, 1.0),
        .init(1.0, 1.0),
    ]

    private(set) var generation: Int = 1

    func markAsDirty() {
        generation += 1
    }

    init(image: CGImage, center: SIMD2<Float>, size: SIMD2<Float>) {
        self.image = image
        self.center = center
        self.size = size
    }

    private var resolvedTexture: any MTLTexture {
        try! Self.textureLoader.newTexture(cgImage: image, options: [
            .allocateMipmaps: NSNumber(booleanLiteral: false),
            .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .SRGB: NSNumber(booleanLiteral: false),
        ])
    }

    private var resolvedVertexBuffer: any MTLBuffer {
        let matrix = matrix2DRotateAndScale(radian: rotation, scale: scale)
        let p1 = simd_mul(matrix, size * 0.5)
        let p2 = simd_mul(matrix, size * SIMD2(0.5, -0.5))

        let vertexes: [SIMD2<Float>] = [
            center - p1,
            center + p1,
            center - p2,
            center + p1,
            center - p1,
            center + p2,
        ]
        return device!.makeBuffer(bytes: vertexes, length: MemoryLayout<SIMD2<Float>>.size * 6)!
    }

    private var resolvedUVBuffer: any MTLBuffer {
        device!.makeBuffer(bytes: Self.uvs, length: MemoryLayout<SIMD2<Float>>.size * 6)!
    }

    private var resolvedBoundingRect: CGRect {
        let matrix = matrix2DRotateAndScale(radian: rotation, scale: scale)
        let p1 = simd_mul(matrix, size * 0.5)
        let p2 = simd_mul(matrix, size * SIMD2(0.5, -0.5))
        let dx = max(abs(p1.x), abs(p2.x))
        let dy = max(abs(p1.y), abs(p2.y))
        let half_size = SIMD2(dx, dy)
        return .init(origin: .from(center - half_size), size: .from(half_size * 2.0))
    }

    func upload(to device: MTLDevice) -> (texture: any MTLTexture, vertexBuffer: any MTLBuffer, uvBuffer: any MTLBuffer, vertexCount: Int) {
        if Self.textureLoader == nil {
            Self.textureLoader = MTKTextureLoader(device: device)
        }
        self.device = device
        return (texture, vertexBuffer, uvBuffer, 6)
    }
}
