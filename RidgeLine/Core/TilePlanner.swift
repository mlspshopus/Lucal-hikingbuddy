import Foundation

struct TilePath: Hashable, Sendable {
    let z: Int
    let x: Int
    let y: Int
}

/// Web-Mercator slippy-map tile math for the offline topo downloader.
enum TilePlanner {
    static let minZoom = 10

    static func tileX(lon: Double, z: Int) -> Int {
        let n = pow(2.0, Double(z))
        return clamp(Int(floor((lon + 180.0) / 360.0 * n)), z)
    }

    static func tileY(lat: Double, z: Int) -> Int {
        let clampedLat = max(-85.0511, min(85.0511, lat))
        let r = clampedLat * Double.pi / 180
        let n = pow(2.0, Double(z))
        return clamp(Int(floor((1.0 - asinh(tan(r)) / Double.pi) / 2.0 * n)), z)
    }

    private static func clamp(_ v: Int, _ z: Int) -> Int {
        max(0, min((1 << z) - 1, v))
    }

    static func tiles(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double,
                      zooms: ClosedRange<Int>) -> [TilePath] {
        var out: [TilePath] = []
        for z in zooms {
            let x0 = tileX(lon: minLon, z: z), x1 = tileX(lon: maxLon, z: z)
            let y0 = tileY(lat: maxLat, z: z), y1 = tileY(lat: minLat, z: z)
            guard x0 <= x1, y0 <= y1 else { continue }
            for x in x0...x1 {
                for y in y0...y1 { out.append(TilePath(z: z, x: x, y: y)) }
            }
        }
        return out
    }

    static func count(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double,
                      zooms: ClosedRange<Int>) -> Int {
        var total = 0
        for z in zooms {
            let w = tileX(lon: maxLon, z: z) - tileX(lon: minLon, z: z) + 1
            let h = tileY(lat: minLat, z: z) - tileY(lat: maxLat, z: z) + 1
            if w > 0, h > 0 { total += w * h }
        }
        return total
    }

    // MARK: Scopes

    /// Total tile requests (across all chosen layers) allowed in one download — keeps us a polite USGS client.
    static let hardCap = 6000

    enum Geometry {
        case box(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)
        /// Every tile within `bufferMeters` of any of the paths (a "corridor" along trails).
        case corridor(paths: [[Coord]], bufferMeters: Double)
    }

    static func count(_ g: Geometry, zooms: ClosedRange<Int>) -> Int {
        switch g {
        case let .box(minLat, maxLat, minLon, maxLon):
            return count(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, zooms: zooms)
        case .corridor:
            return tiles(g, zooms: zooms).count
        }
    }

    static func tiles(_ g: Geometry, zooms: ClosedRange<Int>) -> [TilePath] {
        switch g {
        case let .box(minLat, maxLat, minLon, maxLon):
            return tiles(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, zooms: zooms)
        case let .corridor(paths, buffer):
            return corridorTiles(paths: paths, bufferMeters: buffer, zooms: zooms)
        }
    }

    static func corridorTiles(paths: [[Coord]], bufferMeters: Double, zooms: ClosedRange<Int>) -> [TilePath] {
        var found = Set<TilePath>()
        for z in zooms {
            let n = 1 << z
            for path in paths where !path.isEmpty {
                let meanLat = path.reduce(0.0) { $0 + $1.lat } / Double(path.count)
                let tileMeters = 40_075_016.686 * cos(meanLat * Double.pi / 180) / Double(n)
                let r = max(0, Int(ceil(bufferMeters / tileMeters)))
                var lastX = -1, lastY = -1

                func add(_ c: Coord) {
                    let x = tileX(lon: c.lon, z: z), y = tileY(lat: c.lat, z: z)
                    if x == lastX && y == lastY { return }
                    lastX = x
                    lastY = y
                    for dx in -r...r {
                        for dy in -r...r {
                            let xx = x + dx, yy = y + dy
                            if xx >= 0, xx < n, yy >= 0, yy < n { found.insert(TilePath(z: z, x: xx, y: yy)) }
                        }
                    }
                }

                add(path[0])
                for (a, b) in zip(path, path.dropFirst()) {
                    let d = GPXTrack.haversine(a, b)
                    let steps = max(1, Int(ceil(d / (tileMeters / 2))))
                    for i in 1...steps {
                        let t = Double(i) / Double(steps)
                        add(Coord(a.lat + (b.lat - a.lat) * t, a.lon + (b.lon - a.lon) * t))
                    }
                }
            }
        }
        return found.sorted { ($0.z, $0.x, $0.y) < ($1.z, $1.x, $1.y) }
    }

    /// Bounding box of coordinates with a fractional pad on each side.
    static func box(around coords: [Coord], pad: Double = 0.1) -> Geometry? {
        guard !coords.isEmpty else { return nil }
        let lats = coords.map(\.lat), lons = coords.map(\.lon)
        let latPad = max((lats.max()! - lats.min()!) * pad, 0.005)
        let lonPad = max((lons.max()! - lons.min()!) * pad, 0.005)
        return .box(minLat: lats.min()! - latPad, maxLat: lats.max()! + latPad,
                    minLon: lons.min()! - lonPad, maxLon: lons.max()! + lonPad)
    }
}
