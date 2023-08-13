//
//  PixelBuffer+Vec3.swift
//  SmallPtSwift
//
//  Created by Brett May on 12/8/2023.
//

import SwiftUI
import PixelBuffer

extension PixelBuffer where T == Vec {

    private struct RGBA {
        var r: UInt8
        var g: UInt8
        var b: UInt8
        var a: UInt8
    }

    var cgImage : CGImage? {
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bytesPerPixel = MemoryLayout<RGBA>.size
        let bytesPerRow = width * bytesPerPixel
        
        let convertedPixels = pixels.map { RGBA(r: UInt8(min($0.r, 1.0) * 255),
                                                g: UInt8(min($0.g, 1.0) * 255),
                                                b: UInt8(min($0.b, 1.0) * 255),
                                                a: 255) }

        guard let providerRef = CGDataProvider(data: Data(bytes: convertedPixels,
                                                          count: height * bytesPerRow) as CFData) else {
            return nil
        }
        
        return CGImage(width: width,
                       height: height,
                       bitsPerComponent: 8,
                       bitsPerPixel: bytesPerPixel * 8,
                       bytesPerRow: bytesPerRow,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: alphaInfo.rawValue),
                       provider: providerRef,
                       decode: nil,
                       shouldInterpolate: true, // <-- should this be false
                       intent: .defaultIntent)
    }
}
