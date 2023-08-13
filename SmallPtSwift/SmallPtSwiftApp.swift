//
//  SmallPtSwiftApp.swift
//  SmallPtSwift
//
//  Created by Brett May on 12/8/2023.
//
import SwiftUI
import PixelBuffer

@main
struct SmallPtSwiftApp: App {
    @StateObject var pathTracer = PathTracer()
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if let cgImage = pathTracer.pixelBuffer.cgImage {
                    Image(decorative: cgImage, scale: 1.0)
                        .interpolation(.none)
                        .resizable()
                }
            }
            .padding()
            .onAppear {
                pathTracer.trace()
            }
        }
    }
}

struct Ray {
    var o: Vec
    var d: Vec
}

// material types, used in radiance()
enum Refl_t {
    case DIFF
    case SPEC
    case REFR
}

struct Sphere: CustomStringConvertible {
    var rad: Double // radius
    var p: Vec // position
    var e: Vec // emission
    var c: Vec // color
    var refl: Refl_t      // reflection type (DIFFuse, SPECular, REFRactive)
    var name: String
    
    func intersect(r: Ray) -> Double? { // returns distance, 0 if nohit
        let op = p-r.o // Solve t^2*d.d + 2*t*(o-p).d + (o-p).(o-p)-R^2 = 0
        let eps = 1e-4
        let b = dot(op, r.d)
        var det: Double = b * b - dot(op, op) + rad * rad
        if det < 0 { return nil }
        det = sqrt(det)
        var t = b - det
        if t > eps { return t }
        t = b + det
        if t > eps { return t }
        return nil
    }
    
    var description: String {
        return "\(name) e:\(e) c:\(c) \(refl)"
    }
}

class PathTracer: ObservableObject {
    
    @Published var pixelBuffer = PixelBuffer(width: 1024, height: 768, backgroundColor: Vec.zero)
    @Published var iFrame = 0
    
    let MAXDEPTH = 32
    
    let spheres: [Sphere] = [ //Scene: radius, position, emission, color, material
        Sphere(rad: 1e5,  p: Vec( 1e5+1,40.8,81.6),     e: .zero, c: Vec(0.75,0.25,0.25), refl: .DIFF, name: "Left"),
        Sphere(rad: 1e5,  p: Vec(-1e5+99,40.8,81.6),    e: .zero, c: Vec(0.25,0.25,0.75), refl: .DIFF, name: "Right"),
        Sphere(rad: 1e5,  p: Vec(50,40.8, 1e5),         e: .zero, c: Vec(0.75,0.75,0.75), refl: .DIFF, name: "Back"),
        Sphere(rad: 1e5,  p: Vec(50,40.8,-1e5+170),     e: .zero, c: .zero,               refl: .DIFF, name: "Front"),
        Sphere(rad: 1e5,  p: Vec(50, 1e5, 81.6),        e: .zero, c: Vec(0.75,0.75,0.75), refl: .DIFF, name: "Floor"),
        Sphere(rad: 1e5,  p: Vec(50, -1e5 + 81.6,81.6), e: .zero, c: Vec(0.75,0.75,0.75), refl: .DIFF, name: "Ceil"),
        Sphere(rad: 16.5, p: Vec(27,16.5,47),           e: .zero, c: Vec(1,1,1) * 0.999,  refl: .SPEC, name: "Mirror Sphere"),
        Sphere(rad: 16.5, p: Vec(73,16.5,78),           e: .zero, c: Vec(1,1,1) * 0.999,  refl: .REFR, name: "Glass Sphere"),
        Sphere(rad: 600,  p: Vec(50,681.6 - 0.27,81.6), e: Vec(12,12,12),  c: .zero,      refl: .DIFF, name: "Light")
    ]

    @inline(__always)
    func clamp(_ x: Double) -> Double {
        x<0 ? 0 : x>1 ? 1 : x
    }
    
    @inline(__always)
    func toInt(_ x: Double) -> Int {
        Int(pow(clamp(x), 1.0/2.2)*255+0.5)
    }
    
    @inline(__always)
    func intersect(r: Ray) -> (Double, Sphere?) {
        let inf: Double = 1e20
        var t = inf
        var intersectedSphere: Sphere?
        
        for sphere in spheres {
            let d = sphere.intersect(r: r)
            if let d, d < t {
                t = d
                intersectedSphere = sphere
            }
        }
        
        return (t, intersectedSphere)
    }
    
    func radiance(r: Ray, depth: Int) -> Vec {
        let (t, intersectedObj) = intersect(r: r)
        guard let obj = intersectedObj else { return .zero } // if miss, return black
        
        let x = r.o + r.d * t
        let n = (x - obj.p).normalized
        let nl = dot(n, r.d) < 0 ? n : n * -1
        var f = obj.c
                
        let p = f.x > f.y && f.x > f.z ? f.x : f.y > f.z ? f.y : f.z // max refl
        
        // Russian Roulette:
        if (depth > 5) {
            if Double.random(in: 0.0...1.0) < p {
                f = f * (1.0/p)
            }
            else {
                return obj.e //R.R.
            }
        }
        
        if depth > MAXDEPTH {
            return obj.e //R.R.
        }

        switch obj.refl {
        // Ideal DIFFUSE reflection
        case .DIFF:
            let r1 = 2 * Double.pi * Double.random(in: 0.0...1.0)
            let r2 =  Double.random(in: 0.0...1.0)
            let r2s = sqrt(r2)
            
            let w = nl
            let u = cross(fabs(w.x) > 0.1 ? Vec(0.0, 1.0, 0.0) : Vec(1.0), w).normalized
            let v = cross(w, u)
            let d = (u * cos(r1) * r2s + v * sin(r1) * r2s + w * sqrt(1-r2)).normalized

            return obj.e + f * radiance(r: Ray(o: x,d: d), depth: depth + 1)

            // Ideal SPECULAR reflection
        case .SPEC:
            return obj.e + f * radiance(r: Ray(o: x, d: r.d-n*2*dot(n, r.d)), depth: depth + 1)
            
            // Ideal dielectric REFRACTION
        case .REFR:
            let reflRay = Ray(o: x, d: r.d - n * 2.0 * dot(n, r.d))
            let into = dot(n, nl) > 0               // Ray from outside going in?
            let nc: Double = 1.0
            let nt: Double = 1.5
            let nnt = into ? nc/nt : nt/nc
            let ddn = dot(r.d, nl)
            let cos2t = 1.0 - nnt * nnt * (1.0 - ddn * ddn)
            
            // Total internal reflection
            if cos2t <= 0 {
                return obj.e + f * radiance(r: reflRay, depth: depth + 1)
            }
            
            let tdir = (r.d * nnt - n * ((into ? 1 : -1 ) * (ddn * nnt + sqrt(cos2t)))).normalized
            let a = nt - nc
            let b = nt + nc
            let R0 = a * a / (b * b)
            let c = 1 - (into ? -ddn : dot(tdir, n))
            let Re = R0 + (1.0 - R0) * c * c * c * c * c
            let Tr = 1 - Re
            let P = 0.25 + 0.5 * Re
            let RP = Re / P
            let TP = Tr / (1.0 - P)
            
            if depth > 2 {
                // Russian Roulette: Double(erand48(&xi)) < P
                return obj.e + f * (Double.random(in: 0.0...1.0) < P
                   ? radiance(r: reflRay, depth: depth + 1) * RP
                   : radiance(r: Ray(o: x, d: tdir), depth: depth + 1) * TP)
            }
            else {
                return obj.e + f * (radiance(r: reflRay, depth: depth + 1) * Re +
                                    radiance(r: Ray(o: x, d: tdir), depth: depth + 1) * Tr)
            }
         }
    }
    
    func trace() {
        let w = 1024
        let h = 768
        let samps = 1
        let cam = Ray(o: Vec(50, 52, 295.6),
                      d: Vec(0.0, -0.042612, -1).normalized) // cam pos, dir
    
        let fov = 0.5135
        let cx = Vec(Double(w) * fov / Double(h), 0.0, 0.0)
        let cy = cross(cx, cam.d).normalized * fov
        var r = Vec.zero
        
        for y in 0..<h { // Loop over image rows
            print("\(Int(Float(y)/Float(h) * 100.0))%")
            for x in 0..<w {  // Loop cols
                for sy in 0..<2 {    // 2x2 subpixel rows
                    for sx in 0..<2 { // 2x2 subpixel cols
                        r = Vec.zero
                        for _ in 0..<samps {
                            let r1 = 2.0 * Double.random(in: 0.0...1.0)
                            let dx = r1 < 1 ? sqrt(r1) - 1.0 : 1.0 - sqrt(2.0 - r1)
                            let r2 = 2.0 *  Double.random(in: 0.0...1.0)
                            let dy = r2 < 1.0 ? sqrt(r2) - 1.0 : 1.0 - sqrt(2.0 - r2)
                            let dPart1 = (((Double(sx) + 0.5 + dx) / 2.0) + Double(x)) / Double(w) - 0.5
                            let dPart2 = (((Double(sy) + 0.5 + dy) / 2.0) + Double(y)) / Double(h) - 0.5
                            let d = cx * dPart1 + cy * dPart2 + cam.d
                            let ray = Ray(o: cam.o + d * 138.0, d: d.normalized)
                            r = r + radiance(r: ray, depth: 0) * (1.0 / Double(samps))
                        } // Camera rays are pushed ^^^^^ forward to start in interior
                        let newPixel = Vec(clamp(r.x), clamp(r.y), clamp(r.z)) * 0.25
                        pixelBuffer[x, (h-1)-y] = pixelBuffer[x, (h-1)-y] + newPixel
                    }
                }
            }
        }
        
        iFrame += 1
    }
 }
