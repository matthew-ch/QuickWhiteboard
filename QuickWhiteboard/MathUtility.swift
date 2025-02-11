//
//  MathUtility.swift
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/6/17.
//

import Foundation
import simd
import Accelerate

let halfOfSqrt2 = Float(2.0).squareRoot() / 2.0

func matrix2DRotateAndScale(radian: Float, scale: Float = 1.0) -> simd_float2x2 {
    let cos_value = cos(radian) * scale
    let sin_value = sin(radian) * scale
    return simd_float2x2(rows: [
        .init(cos_value, -sin_value),
        .init(sin_value, cos_value),
    ])
}

func distanceFromPointToLineSegment(point: Point2D, segmentPoints p1: Point2D, _ p2: Point2D) -> Float {
    let u1 = point - p1
    let v1 = p2 - p1
    if simd_dot(u1, v1) <= 0 {
        return simd_length(point - p1)
    }
    let u2 = point - p2
    let v2 = p1 - p2
    let dotProduct = simd_dot(u2, v2)
    if dotProduct <= 0 {
        return simd_length(point - p2)
    }
    let u2Length = simd_length(u2)
    let cosValue = dotProduct / u2Length / simd_length(v2)
    let sinValue = sqrt(1 - pow(cosValue, 2))
    return u2Length * sinValue
}

func isPointInside(point: Point2D, p1: Point2D, p2: Point2D, p3: Point2D) -> Bool {
    let u = p2 - p1
    let v = p3 - p1
    let p = point - p1
    let d = u.x * v.y - u.y * v.x
    let da = p.x * v.y - p.y * v.x
    let db = p.y * u.x - p.x * u.y
    if d.isZero {
        if da.isZero && db.isZero {
            let uu = simd_dot(u, u)
            let vv = simd_dot(v, v)
            let pp = simd_dot(p, p)
            switch (uu.isZero, vv.isZero) {
            case (true, true):
                return pp.isZero
            case (true, false):
                return pp <= vv && simd_dot(p, v) >= 0.0
            case (false, true):
                return pp <= uu && simd_dot(p, u) >= 0.0
            case (false, false):
                return pp <= vv && simd_dot(p, v) >= 0.0 || pp <= uu && simd_dot(p, u) >= 0.0
            }
        } else {
            return false
        }
    } else {
        return da * d >= 0.0 && db * d >= 0.0 && abs(da + db) <= abs(d)
    }
}

nonisolated(unsafe) private var cachedDivideResult = [Int: [Point2D]]()
func divideUnitCircle(count: Int) -> [Point2D] {
    if let cached = cachedDivideResult[count] {
        return cached
    }
    let sectorAngle = Float.pi * 2.0 / Float(count)
    let angles = (0..<count).map({ sectorAngle * Float($0) })
    var cosValues = Array<Float>(repeating: 0.0, count: count)
    var sinValues = Array<Float>(repeating: 0.0, count: count)
    vForce.sincos(angles, sinResult: &sinValues, cosResult: &cosValues)

    var points: [Point2D] = []
    for i in 0..<count {
        points.append(.init(x: cosValues[i], y: sinValues[i]))
    }
    cachedDivideResult[count] = points
    return points
}
