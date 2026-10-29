import Foundation

struct TilePath: Hashable, Sendable {
    let z: Int
    let x: Int
    let y: Int
}

/// Web-Mercator slippy-map tile math for the offline topo downloader.
enum TilePlanner {
    static let minZoom = 10
    static let maxZoomCap = 16
    static let maxTiles = 2500
    /// Rough average size of a USGS Topo tile, for the "about N MB" estimate.
    static let averageTileBytes = 30_000

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

    /// Picks the deepest zoom (≤ 16) whose tile count for the box stays under `maxTiles`.
    static func plan(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) -> (tiles: [TilePath], maxZoom: Int) {
        var best: (tiles: [TilePath], maxZoom: Int)?
        var z = maxZoomCap
        while z >= minZoom {
            if count(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, zooms: minZoom...z) <= maxTiles {
                best = (tiles(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, zooms: minZoom...z), z)
                break
            }
            z -= 1
        }
        return best ?? (tiles(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, zooms: minZoom...minZoom), minZoom)
    }
}
