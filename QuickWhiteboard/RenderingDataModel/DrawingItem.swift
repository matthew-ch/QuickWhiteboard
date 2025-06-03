//
//  DrawingItem.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/2/3.
//

import Foundation
import Metal
import simd

struct PointSample {
    let location: Point2D
}

class DrawingItem: RenderItem, CanMarkAsDirty, HasGeneration {

    var globalPosition: CGPoint = .zero

    var points: [PointSample] {
        []
    }
    var localBoundingRect: CGRect {
        CGRect(origin: .init(x: CGFloat.infinity, y: CGFloat.infinity), size: .zero)
    }
    var isClosedPath: Bool {
        false
    }

    var hidden: Bool = false

    var frozen: Bool = false

    var isOpaque: Bool {
        strokeColor.w == 1.0
    }

    let strokeColor: SIMD4<Float>
    let strokeWidth: Float

    private(set) var generation = 1

    @OnDemand(\DrawingItem.generateVertexBuffer)
    private var vertexBuffer: (any MTLBuffer)

    init(strokeColor: SIMD4<Float>, strokeWidth: CGFloat) {
        self.strokeColor = strokeColor
        self.strokeWidth = Float(strokeWidth)
    }

    func generateTriangles(point: PointSample, previousPoint: PointSample?, nextPoint: PointSample?) -> [Point2D] {
        let location = point.location
        let previousLocation = previousPoint?.location
        let nextLocation = nextPoint?.location

        let pointTriangleCount = max(Int(ceilf(Float.pi * strokeWidth / 2.0)), 4)
        var points: [Point2D] = divideUnitCircle(count: pointTriangleCount)
        points.append(points[0])
        let radius = strokeWidth / 2.0
        var visibleIndices = Array(0..<pointTriangleCount)

        var result: [Point2D] = []

        if let nextLocation {
            let v = normalize(location - nextLocation)
            visibleIndices = visibleIndices.filter { i in
                simd_dot(points[i], v) > 0 || simd_dot(points[i + 1], v) > 0
            }
        }

        if let previousLocation {
            let v = normalize(location - previousLocation)
            let u = Vector2D(-v.y, v.x)
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

    func generateVertexes(points: [PointSample]) -> [Point2D] {
        var result: [Point2D] = []
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
        return device!.makeBuffer(bytes: vertexes, length: MemoryLayout<Point2D>.size * max(vertexes.count, 1))!
    }

    func upload(to device: MTLDevice) -> (vetexBuffer: any MTLBuffer, vertexCount: Int) {
        self.device = device
        return (vertexBuffer, vertexBuffer.length / MemoryLayout<Point2D>.size)
    }

    final func markAsDirty() {
        generation += 1
    }

    func distance(to globalLocation: CGPoint) -> Float {
        let location = globalLocation.float2 - globalPosition.float2
        var previousPoint = isClosedPath ? points.last! : points[0]
        var minDistance = Float.infinity
        let halfStroke = strokeWidth / 2.0
        for point in points {
            let d = distanceFromPointToLineSegment(point: location, segmentPoints: previousPoint.location, point.location) - halfStroke
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
    override var localBoundingRect: CGRect {
        _boundingRect
    }

    private var resolvedBoundingRect: CGRect {
        assert(!points.isEmpty)
        var minxy = Point2D(x: Float.infinity, y: Float.infinity)
        var maxxy = Point2D(x: -Float.infinity, y: -Float.infinity)
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
    private var endPoint: Point2D

    @OnDemand(\LineItem.resolvedBoundingRect)
    private var _boundingRect: CGRect
    override var localBoundingRect: CGRect {
        _boundingRect
    }

    @DirtyMarking
    var from: Point2D = .zero

    @DirtyMarking
    var to: Point2D = .zero

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

    private var resolvedEndPoint: Point2D {
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
            let u = Point2D(Self.dirXs[maxIndex], Self.dirYs[maxIndex]) * maxValue
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
    override var localBoundingRect: CGRect {
        _boundingRect
    }

    override var isClosedPath: Bool {
        return _points.count == 4
    }

    @OnDemand(\RectangleItem.resolvedEndPoint)
    private var endPoint: Point2D

    @DirtyMarking
    var from: Point2D = .zero

    @DirtyMarking
    var to: Point2D = .zero

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

    private var resolvedEndPoint: Point2D {
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
            let from: Point2D
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
    override var localBoundingRect: CGRect {
        _boundingRect
    }

    override var isClosedPath: Bool {
        return _points.count > 2
    }

    @DirtyMarking
    var from: Point2D = .zero

    @DirtyMarking
    var to: Point2D = .zero

    @DirtyMarking
    var isCircle = false

    @DirtyMarking
    var isCenterMode = false

    private func calcCenterRxRy() -> (Point2D, Float, Float) {
        let center: Point2D
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
        let rs = Vector2D(x: rx + strokeWidth / 2.0, y: ry + strokeWidth / 2.0)
        return CGRect(origin: .from(center - rs), size: .from(rs * 2.0))
    }

    private var resolvedPoints: [PointSample] {
        if from == to {
            return [PointSample(location: from)]
        }
        let (center, rx, ry) = calcCenterRxRy()
        if rx == 0.0 || ry == 0.0 {
            return [
                PointSample(location: center - .init(x: rx, y: ry)),
                PointSample(location: center + .init(x: rx, y: ry))
            ]
        }
        var points: [Point2D] = []
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
        return points.map { PointSample(location: $0 + center) }
    }
}
