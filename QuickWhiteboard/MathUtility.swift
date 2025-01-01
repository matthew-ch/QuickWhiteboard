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

func distanceFromPointToLineSegment(point: SIMD2<Float>, segmentPoints p1: SIMD2<Float>, _ p2: SIMD2<Float>) -> Float {
    let u1 = point - p1
    let v1 = p2 - p1
    if simd_dot(u1, v1) <= 0 {
        return simd_length(point - p1)
    }
    let u2 = point - p2
    let v2 = p1 - p2
    let dotPorduct = simd_dot(u2, v2)
    if dotPorduct <= 0 {
        return simd_length(point - p2)
    }
    let u2Length = simd_length(u2)
    let cosValue = dotPorduct / u2Length / simd_length(v2)
    let sinValue = sqrt(1 - pow(cosValue, 2))
    return u2Length * sinValue
}

func divideUnitCircle(count: Int) -> [SIMD2<Float>] {
    let sectorAngle = Float.pi * 2.0 / Float(count)
    let angles = (0..<count).map({ sectorAngle * Float($0) })
    var cosValues = Array<Float>(repeating: 0.0, count: count)
    var sinValues = Array<Float>(repeating: 0.0, count: count)
    vForce.sincos(angles, sinResult: &sinValues, cosResult: &cosValues)

    var points: [SIMD2<Float>] = []
    for i in 0..<count {
        points.append(.init(x: cosValues[i], y: sinValues[i]))
    }
    return points
}
