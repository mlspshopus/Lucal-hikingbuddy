import Foundation

/// A named hiking path assembled from OpenStreetMap ways (free data, no API key).
struct DiscoveredTrail: Identifiable, Hashable {
    var name: String
    var path: [Coord]
    var miles: Double
    var wayCount: Int
    /// Straight-line distance from the search center to the trail's start, in miles.
    var startDistanceMiles: Double
    var gainForwardFt: Int?
    var gainReverseFt: Int?

    var id: String { "\(name)|\(path.first?.linkParam ?? "")" }
    var start: Coord { path[0] }

    func estimatedMinutes(outAndBack: Bool) -> Int {
        if outAndBack {
            return HikeMath.minutes(miles: miles * 2, gainFt: (gainForwardFt ?? 0) + (gainReverseFt ?? 0))
        }
        return HikeMath.minutes(miles: miles, gainFt: gainForwardFt ?? 0)
    }

    /// Converts to a saved route. Out-and-back doubles distance and counts the climb in both directions.
    func asRoute(outAndBack: Bool) -> HikeRoute {
        let gain = outAndBack ? (gainForwardFt ?? 0) + (gainReverseFt ?? 0) : (gainForwardFt ?? 0)
        let total = outAndBack ? miles * 2 : miles
        let difficulty: String
        switch (Double(gain) / max(total, 0.1)) {
        case ..<150: difficulty = "Easy"
        case ..<300: difficulty = "Moderate"
        default: difficulty = "Strenuous"
        }
        return HikeRoute(
            id: "osm-\(UUID().uuidString)",
            name: outAndBack ? "\(name) (out & back)" : name,
            miles: (total * 10).rounded() / 10,
            gainFt: gain,
            difficulty: difficulty,
            style: outAndBack ? "Out & back" : "One way",
            blurb: "Found from OpenStreetMap data. Distance, climb and time are estimates — confirm on an official map.",
            trailheadID: nil,
            path: path,
            isSketchPath: false,
            isImported: true)
    }
}

enum TrailDiscovery {
    static let endpoints = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter"
    ]

    /// Overpass QL: every named foot path within the radius, with full geometry.
    static func query(center: Coord, radiusMeters: Int) -> String {
        "[out:json][timeout:25];way(around:\(radiusMeters),\(center.lat),\(center.lon))[\"highway\"~\"^(path|footway)$\"][\"name\"];out geom;"
    }

    /// Form-encoded POST body for the Overpass interpreter.
    static func requestBody(_ query: String) -> Data? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        return encoded.map { Data("data=\($0)".utf8) }
    }

    private struct Response: Decodable {
        struct Point: Decodable { let lat: Double; let lon: Double }
        struct Element: Decodable {
            let type: String
            let tags: [String: String]?
            let geometry: [Point]?
        }
        let elements: [Element]
    }

    /// Groups ways by trail name, stitches connected pieces into one line, and sorts by start distance.
    static func parse(_ data: Data, center: Coord, minMiles: Double = 0.25) throws -> [DiscoveredTrail] {
        let r = try JSONDecoder().decode(Response.self, from: data)
        var byName: [String: [[Coord]]] = [:]
        for e in r.elements where e.type == "way" {
            guard let name = e.tags?["name"]?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
                  let geom = e.geometry, geom.count >= 2 else { continue }
            byName[name, default: []].append(geom.map { Coord($0.lat, $0.lon) })
        }

        var out: [DiscoveredTrail] = []
        for (name, ways) in byName {
            let line = chain(ways)
            guard line.count >= 2 else { continue }
            let miles = length(line) / 1609.344
            guard miles >= minMiles else { continue }
            let startMeters = GPXTrack.haversine(center, line[0])
            out.append(DiscoveredTrail(name: name, path: line, miles: miles, wayCount: ways.count,
                                       startDistanceMiles: startMeters / 1609.344))
        }
        return out.sorted {
            $0.startDistanceMiles == $1.startDistanceMiles ? $0.name < $1.name : $0.startDistanceMiles < $1.startDistanceMiles
        }
    }

    static func length(_ line: [Coord]) -> Double {
        var m = 0.0
        for (a, b) in zip(line, line.dropFirst()) { m += GPXTrack.haversine(a, b) }
        return m
    }

    /// Greedily joins ways end-to-end (flipping as needed), starting from the longest.
    /// Pieces that don't connect within `joinMeters` are left out.
    static func chain(_ segments: [[Coord]], joinMeters: Double = 40) -> [Coord] {
        var remaining = segments.filter { $0.count >= 2 }.sorted { length($0) > length($1) }
        guard !remaining.isEmpty else { return [] }
        var line = remaining.removeFirst()

        var extended = true
        while extended && !remaining.isEmpty {
            extended = false
            for i in remaining.indices {
                let s = remaining[i]
                guard let head = line.first, let tail = line.last, let sFirst = s.first, let sLast = s.last else { continue }
                if GPXTrack.haversine(tail, sFirst) <= joinMeters {
                    line += s.dropFirst()
                } else if GPXTrack.haversine(tail, sLast) <= joinMeters {
                    line += s.reversed().dropFirst()
                } else if GPXTrack.haversine(head, sLast) <= joinMeters {
                    line = s + line.dropFirst()
                } else if GPXTrack.haversine(head, sFirst) <= joinMeters {
                    line = Array(s.reversed()) + line.dropFirst()
                } else {
                    continue
                }
                remaining.remove(at: i)
                extended = true
                break
            }
        }
        return line
    }

    // MARK: Elevation (Open-Meteo, free)

    /// Evenly spaced points along a path, at most `limit` (the elevation API accepts 100 per call).
    static func samplePoints(_ path: [Coord], limit: Int = 100) -> [Coord] {
        guard path.count > limit else { return path }
        let step = Double(path.count - 1) / Double(limit - 1)
        return (0..<limit).map { path[Int((Double($0) * step).rounded())] }
    }

    static func elevationURL(for points: [Coord]) -> URL? {
        var c = URLComponents(string: "https://api.open-meteo.com/v1/elevation")
        c?.queryItems = [
            URLQueryItem(name: "latitude", value: points.map { String(format: "%.5f", $0.lat) }.joined(separator: ",")),
            URLQueryItem(name: "longitude", value: points.map { String(format: "%.5f", $0.lon) }.joined(separator: ","))
        ]
        return c?.url
    }

    static func parseElevations(_ data: Data) -> [Double]? {
        struct R: Decodable { let elevation: [Double] }
        return try? JSONDecoder().decode(R.self, from: data).elevation
    }

    /// Climb in each direction for a series of sampled elevations (meters).
    static func gains(_ elevationsMeters: [Double]) -> (forward: Int, reverse: Int) {
        (HikeMath.gainFt(elevationsMeters: elevationsMeters),
         HikeMath.gainFt(elevationsMeters: elevationsMeters.reversed()))
    }
}
