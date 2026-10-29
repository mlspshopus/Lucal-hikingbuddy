import Foundation

/// Free, public-domain USGS "The National Map" tile services. All serve zoom 0–16 with no API key.
enum TileSource: String, CaseIterable, Codable, Identifiable, Sendable {
    case topo, aerial, aerialTopo, relief

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topo: return "Topo"
        case .aerial: return "USGS Aerial"
        case .aerialTopo: return "Aerial + Topo"
        case .relief: return "Shaded Relief"
        }
    }

    var blurb: String {
        switch self {
        case .topo: return "Contour lines, trails and roads. Best for hiking."
        case .aerial: return "Satellite-style photo imagery."
        case .aerialTopo: return "Photo imagery with topo labels and trails."
        case .relief: return "Terrain shading that shows ridges and valleys."
        }
    }

    var symbol: String {
        switch self {
        case .topo: return "map.fill"
        case .aerial: return "globe.americas.fill"
        case .aerialTopo: return "square.2.layers.3d.fill"
        case .relief: return "mountain.2.fill"
        }
    }

    var service: String {
        switch self {
        case .topo: return "USGSTopo"
        case .aerial: return "USGSImageryOnly"
        case .aerialTopo: return "USGSImageryTopo"
        case .relief: return "USGSShadedReliefOnly"
        }
    }

    /// Rough average tile size, for the "about N MB" estimate.
    var averageTileBytes: Int {
        switch self {
        case .topo: return 30_000
        case .aerial: return 25_000
        case .aerialTopo: return 30_000
        case .relief: return 10_000
        }
    }

    static let maxZoom = 16

    /// MapKit tile template ({z}/{y}/{x} order is what ArcGIS tile services expect).
    var template: String {
        "https://basemap.nationalmap.gov/arcgis/rest/services/\(service)/MapServer/tile/{z}/{y}/{x}"
    }

    func url(for t: TilePath) -> URL? {
        URL(string: "https://basemap.nationalmap.gov/arcgis/rest/services/\(service)/MapServer/tile/\(t.z)/\(t.y)/\(t.x)")
    }

    static let attribution = "USGS The National Map"
}

struct TileRequest: Hashable, Sendable {
    let source: TileSource
    let tile: TilePath
}

/// How deep to zoom when saving an area. Deeper = sharper but many more tiles.
enum DetailLevel: String, CaseIterable, Identifiable {
    case overview, standard, detailed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .standard: return "Standard"
        case .detailed: return "Detailed"
        }
    }

    var maxZoom: Int {
        switch self {
        case .overview: return 13
        case .standard: return 15
        case .detailed: return 16
        }
    }

    var blurb: String {
        switch self {
        case .overview: return "Zoom 10–13 · see the whole region and big landmarks."
        case .standard: return "Zoom 10–15 · trail junctions and creeks. Good default."
        case .detailed: return "Zoom 10–16 · sharpest USGS detail. Use on a single trail."
        }
    }

    var zooms: ClosedRange<Int> { TilePlanner.minZoom...maxZoom }
}
