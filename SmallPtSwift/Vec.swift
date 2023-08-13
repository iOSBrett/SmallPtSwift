//
//  Vec.swift
//  SmallPtSwift
//
//  Created by Brett May on 12/8/2023.
//

import Foundation

public typealias Vec = Vector3

public struct Vector3: Hashable, Equatable, Codable {
    public let x : Double
    public let y : Double
    public let z : Double
    
    public var magnitude: Double {
        return sqrt(x*x + y*y + z*z)
    }
    
    public var normalized: Vector3 {
        let magnitude = self.magnitude
        return Vector3(x: x / magnitude, y: y / magnitude, z: z / magnitude)
    }
    
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(_ x: Double) {
        self.x = x
        self.y = x
        self.z = x
    }
    
    public init(r: Double, g: Double, b: Double) {
        self.x = r
        self.y = g
        self.z = b
    }
    
    public init(array: [Double]) {
        assert(array.count == 3)
        self.x = array[0]
        self.y = array[1]
        self.z = array[2]
    }
    
    public init(_ vec2: Vector3, _ z: Double) {
        self.x = vec2.x
        self.y = vec2.y
        self.z = z
    }
}

extension Vector3 {
    public var xyz: Vector3 { return self }
    
    public var r: Double { return x }
    public var g: Double { return y }
    public var b: Double { return z }
    
    public var asArray: [Double] {
        return [x, y, z]
    }
}

extension Vector3: AdditiveArithmetic {

    public static var zero: Vector3 {
        return Vector3(x: 0.0, y: 0.0, z: 0.0)
    }
    
    // MARK: Multiplication

    public static func *(_ lhs: Vector3, _ rhs: Double) -> Vector3 {
        return Vector3(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }
    
    public static func *=(lhs: inout Vector3, rhs: Double) {
        lhs = lhs * rhs
    }

    public static func *(_ lhs: Double, _ rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs * rhs.x, y: lhs * rhs.y, z:lhs * rhs.z)
    }

    public static func *(_ lhs: Vector3, _ rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x * rhs.x, y: lhs.y * rhs.y, z: lhs.z * rhs.z)
    }
    
     public static func *=(lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs * rhs
    }
    
    // MARK: Division

    public static func /(_ lhs: Vector3, _ rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x / rhs.x, y: lhs.y / rhs.y, z: lhs.z / rhs.z)
    }

    public static func /=(lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs / rhs
    }
    
    public static func /(_ lhs: Vector3, _ rhs: Double) -> Vector3 {
        return Vector3(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
    }
    
    public static func /=(lhs: inout Vector3, rhs: Double) {
        lhs = lhs / rhs
    }
    
    public static func /(_ lhs: Double, _ rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs / rhs.x, y: lhs / rhs.y, z: lhs / rhs.z)
    }
    
    // MARK: Subtraction

    public static func -(_ lhs: Vector3, _ rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    public static func -=(lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs - rhs
    }
    
    public static func -(_ lhs: Vector3, _ rhs: Double) -> Vector3 {
        return Vector3(x: lhs.x - rhs, y: lhs.y - rhs, z: lhs.z - rhs)
    }
    
    public static func -=(lhs: inout Vector3, rhs: Double) {
        lhs = lhs - rhs
    }

    public static func -(_ lhs: Double, _ rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs - rhs.x, y: lhs - rhs.y, z: lhs - rhs.z)
    }

    // MARK: Addition

    public static func +(_ lhs: Vector3, _ rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    public static func +=(lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs + rhs
    }
    
    public static func +(_ lhs: Vector3, _ rhs: Double) -> Vector3 {
        return Vector3(x: lhs.x + rhs, y: lhs.y + rhs, z: lhs.z + rhs)
    }
    
    public static func +=(lhs: inout Vector3, rhs: Double) {
        lhs = lhs + rhs
    }

    public static func +(_ lhs: Double, _ rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs + rhs.x, y: lhs + rhs.y, z: lhs + rhs.z)
    }

    // MARK: Unary

    public static prefix func -(v: Vector3) -> Vector3 {
        return Vector3(x: -v.x, y: -v.y, z: -v.z)
    }
}

public func dot(_ lhs: Vector3, _ rhs: Vector3) -> Double {
    return (lhs.x * rhs.x) + (lhs.y * rhs.y) + (lhs.z * rhs.z)
}

public func cross(_ lhs: Vector3, _ rhs: Vector3) -> Vector3 {
    return Vector3(x: lhs.y * rhs.z - lhs.z * rhs.y,
                   y: lhs.z * rhs.x - lhs.x * rhs.z,
                   z: lhs.x * rhs.y - lhs.y * rhs.x)
}
