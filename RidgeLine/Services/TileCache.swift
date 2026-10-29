import Foundation
import MapKit

/// On-disk store for USGS topo tiles: `OfflineTiles/<z>/<x>/<y>.tile` in Application Support.
final class TileDiskCache {
    static let shared = TileDiskCache()

    private let root: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        root = base.appendingPathComponent("OfflineTiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true   // re-downloadable, so keep it out of iCloud backups
        var dir = root
        try? dir.setResourceValues(values)
    }

    private func fileURL(_ t: TilePath) -> URL {
        root.appendingPathComponent("\(t.z)", isDirectory: true)
            .appendingPathComponent("\(t.x)", isDirectory: true)
            .appendingPathComponent("\(t.y).tile")
    }

    func has(_ t: TilePath) -> Bool { FileManager.default.fileExists(atPath: fileURL(t).path) }

    func read(_ t: TilePath) -> Data? { try? Data(contentsOf: fileURL(t)) }

    func write(_ data: Data, _ t: TilePath) {
        let url = fileURL(t)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: root)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func sizeBytes() -> Int {
        guard let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total = 0
        for case let url as URL in e {
            total += (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        return total
    }
}

enum USGSTopo {
    /// USGS The National Map — free, no API key, public domain.
    static let template = "https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}"

    static func url(for t: TilePath) -> URL? {
        URL(string: "https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/\(t.z)/\(t.y)/\(t.x)")
    }

    static let attribution = "Topo: USGS The National Map"
}

/// Topographic overlay that serves tiles from disk first and fills the cache as you browse online.
final class CachedTileOverlay: MKTileOverlay {
    init() {
        super.init(urlTemplate: USGSTopo.template)
        canReplaceMapContent = true
        minimumZ = 3
        maximumZ = 16
        tileSize = CGSize(width: 256, height: 256)
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let tile = TilePath(z: path.z, x: path.x, y: path.y)
        if let data = TileDiskCache.shared.read(tile) {
            result(data, nil)
            return
        }
        guard let url = USGSTopo.url(for: tile) else {
            result(nil, URLError(.badURL))
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data, !data.isEmpty, (response as? HTTPURLResponse)?.statusCode == 200 {
                TileDiskCache.shared.write(data, tile)
                result(data, nil)
            } else {
                result(nil, error ?? URLError(.badServerResponse))
            }
        }.resume()
    }
}

/// Pre-downloads topo tiles for a map region so the trail map works with zero signal.
@MainActor
final class OfflineDownloader: ObservableObject {
    @Published var isRunning = false
    @Published var progress = 0.0
    @Published var message: String?
    @Published var savedBytes = TileDiskCache.shared.sizeBytes()

    private var task: Task<Void, Never>?

    struct Plan {
        let tiles: [TilePath]
        let maxZoom: Int
        var estimatedMB: Double { Double(tiles.count * TilePlanner.averageTileBytes) / 1_000_000 }
    }

    static func plan(for region: MKCoordinateRegion) -> Plan {
        let p = TilePlanner.plan(
            minLat: region.center.latitude - region.span.latitudeDelta / 2,
            maxLat: region.center.latitude + region.span.latitudeDelta / 2,
            minLon: region.center.longitude - region.span.longitudeDelta / 2,
            maxLon: region.center.longitude + region.span.longitudeDelta / 2)
        return Plan(tiles: p.tiles, maxZoom: p.maxZoom)
    }

    func start(_ plan: Plan) {
        guard !isRunning else { return }
        isRunning = true
        progress = 0
        message = nil
        let tiles = plan.tiles
        task = Task { [weak self] in
            var done = 0
            var failed = 0
            for chunk in stride(from: 0, to: tiles.count, by: 8).map({ Array(tiles[$0..<min($0 + 8, tiles.count)]) }) {
                if Task.isCancelled { break }
                let results = await withTaskGroup(of: Bool.self) { group -> [Bool] in
                    for t in chunk { group.addTask { await OfflineDownloader.fetch(t) } }
                    var out: [Bool] = []
                    for await ok in group { out.append(ok) }
                    return out
                }
                done += chunk.count
                failed += results.filter { !$0 }.count
                self?.progress = Double(done) / Double(max(tiles.count, 1))
            }
            guard let self else { return }
            self.isRunning = false
            self.savedBytes = TileDiskCache.shared.sizeBytes()
            if Task.isCancelled {
                self.message = "Download cancelled."
            } else if failed == 0 {
                self.message = "Saved \(tiles.count) tiles — this area now works offline."
            } else {
                self.message = "Saved \(tiles.count - failed) of \(tiles.count) tiles. Reconnect and try again to fill the gaps."
            }
        }
    }

    func cancel() { task?.cancel() }

    func clearAll() {
        TileDiskCache.shared.clear()
        savedBytes = 0
        message = "Offline tiles cleared."
    }

    private nonisolated static func fetch(_ t: TilePath) async -> Bool {
        if TileDiskCache.shared.has(t) { return true }
        guard let url = USGSTopo.url(for: t) else { return false }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else { return false }
            TileDiskCache.shared.write(data, t)
            return true
        } catch {
            return false
        }
    }
}
