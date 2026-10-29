import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

struct GPXTrack {
    var name: String
    var points: [Coord]
    var elevationsMeters: [Double]

    var miles: Double {
        var meters = 0.0
        for (a, b) in zip(points, points.dropFirst()) { meters += GPXTrack.haversine(a, b) }
        return meters / 1609.344
    }

    /// Cumulative climb in feet. Ignores ±1 m jitter so GPS noise doesn't inflate the number.
    var gainFt: Int {
        guard elevationsMeters.count > 1 else { return 0 }
        var gain = 0.0
        var anchor = elevationsMeters[0]
        for e in elevationsMeters.dropFirst() {
            if e - anchor > 1 { gain += e - anchor; anchor = e }
            else if anchor - e > 1 { anchor = e }
        }
        return Int((gain * 3.28084).rounded())
    }

    static func haversine(_ a: Coord, _ b: Coord) -> Double {
        let r = 6_371_000.0
        let p1 = a.lat * .pi / 180, p2 = b.lat * .pi / 180
        let dp = p2 - p1, dl = (b.lon - a.lon) * .pi / 180
        let h = sin(dp / 2) * sin(dp / 2) + cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2)
        return 2 * r * asin(min(1, sqrt(h)))
    }
}

/// Minimal GPX reader: `<trkpt>` and `<rtept>` with optional `<ele>`; first `<name>` becomes the track name.
final class GPXParser: NSObject, XMLParserDelegate {
    private var points: [Coord] = []
    private var elevations: [Double] = []
    private var name: String?
    private var buffer = ""
    private var inPoint = false
    private var pendingElevation: Double?

    static func parse(_ data: Data) -> GPXTrack? {
        let delegate = GPXParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse(), delegate.points.count >= 2 else { return nil }
        return GPXTrack(name: delegate.name ?? "Imported route",
                        points: delegate.points,
                        elevationsMeters: delegate.elevations.count == delegate.points.count ? delegate.elevations : [])
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        buffer = ""
        if elementName == "trkpt" || elementName == "rtept" {
            if let lat = attributeDict["lat"].flatMap(Double.init), let lon = attributeDict["lon"].flatMap(Double.init) {
                points.append(Coord(lat, lon))
                inPoint = true
                pendingElevation = nil
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "name":
            if name == nil, !text.isEmpty { name = text }
        case "ele":
            if inPoint { pendingElevation = Double(text) }
        case "trkpt", "rtept":
            if inPoint { elevations.append(pendingElevation ?? Double.nan) }
            inPoint = false
        default:
            break
        }
        buffer = ""
    }
}
