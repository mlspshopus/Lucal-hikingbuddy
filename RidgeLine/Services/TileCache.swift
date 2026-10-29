import Foundation
import MapKit

/// On-disk store for map tiles: `OfflineTilesV2/<source>/<z>/<x>/<y>.tile` in Application Support.
final class TileDiskCache {
    static let shared = TileDiskCache()

    private let root: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        root = base.appendingPathComponent("OfflineTilesV2", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true   // re-downloadable, so keep it out of iCloud backups
        var dir = root
        try? dir.setResourceValues(values)
        // The first release cached topo tiles flat in "OfflineTiles"; they are re-downloadable, so drop them.
        try? FileManager.default.removeItem(at: base.appendingPathComponent("OfflineTiles", isDirectory: true))
    }

    private func folder(_ source: TileSource) -> URL {
        root.appendingPathComponent(source.rawValue, isDirectory: true)
    }

    private func fileURL(_ r: TileRequest) -> URL {
        folder(r.source)
            .appendingPathComponent("\(r.tile.z)", isDirectory: true)
            .appendingPathComponent("\(r.tile.x)", isDirectory: true)
            .appendingPathComponent("\(r.tile.y).tile")
    }

    func has(_ r: TileRequest) -> Bool { FileManager.default.fileExists(atPath: fileURL(r).path) }

    func read(_ r: TileRequest) -> Data? { try? Data(contentsOf: fileURL(r)) }

    func write(_ data: Data, _ r: TileRequest) {
        let url = fileURL(r)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    func clear(_ source: TileSource) {
        try? FileManager.default.removeItem(at: folder(source))
    }

    func sizeBytes(_ source: TileSource) -> Int {
        guard let e = FileManager.default.enumerator(at: folder(source), includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total = 0
        for case let url as URL in e {
            total += (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        return total
    }
}

/// Tile overlay that serves tiles from disk first and fills the cache as you browse online.
final class CachedTileOverlay: MKTileOverlay {
    let source: TileSource

    init(source: TileSource) {
        self.source = source
        super.init(urlTemplate: source.template)
        canReplaceMapContent = true
        minimumZ = 3
        maximumZ = TileSource.maxZoom
        tileSize = CGSize(width: 256, height: 256)
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let request = TileRequest(source: source, tile: TilePath(z: path.z, x: path.x, y: path.y))
        if let data = TileDiskCache.shared.read(request) {
            result(data, nil)
            return
        }
        guard let url = source.url(for: request.tile) else {
            result(nil, URLError(.badURL))
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data, !data.isEmpty, (response as? HTTPURLResponse)?.statusCode == 200 {
                TileDiskCache.shared.write(data, request)
                result(data, nil)
            } else {
                result(nil, error ?? URLError(.badServerResponse))
            }
        }.resume()
    }
}

/// Pre-downloads tiles so the map works with zero signal.
@MainActor
final class OfflineDownloader: ObservableObject {
    @Published var isRunning = false
    @Published var progress = 0.0
    @Published var message: String?
    @Published var savedBytes: [TileSource: Int] = [:]

    private var task: Task<Void, Never>?

    init() { refreshSizes() }

    var totalSavedBytes: Int { savedBytes.values.reduce(0, +) }

    func refreshSizes() {
        var sizes: [TileSource: Int] = [:]
        for s in TileSource.allCases { sizes[s] = TileDiskCache.shared.sizeBytes(s) }
        savedBytes = sizes
    }

    func start(_ requests: [TileRequest]) {
        guard !isRunning, !requests.isEmpty else { return }
        isRunning = true
        progress = 0
        message = nil
        task = Task { [weak self] in
            var done = 0
            var failed = 0
            for chunk in stride(from: 0, to: requests.count, by: 8).map({ Array(requests[$0..<min($0 + 8, requests.count)]) }) {
                if Task.isCancelled { break }
                let results = await withTaskGroup(of: Bool.self) { group -> [Bool] in
                    for r in chunk { group.addTask { await OfflineDownloader.fetch(r) } }
                    var out: [Bool] = []
                    for await ok in group { out.append(ok) }
                    return out
                }
                done += chunk.count
                failed += results.filter { !$0 }.count
                self?.progress = Double(done) / Double(max(requests.count, 1))
            }
            guard let self else { return }
            self.isRunning = false
            self.refreshSizes()
            if Task.isCancelled {
                self.message = "Download cancelled."
            } else if failed == 0 {
                self.message = "Saved \(requests.count) tiles — this area now works offline."
            } else {
                self.message = "Saved \(requests.count - failed) of \(requests.count) tiles. Reconnect and try again to fill the gaps."
            }
        }
    }

    func cancel() { task?.cancel() }

    func clear(_ source: TileSource) {
        TileDiskCache.shared.clear(source)
        refreshSizes()
        message = "\(source.title) tiles cleared."
    }

    func clearAll() {
        for s in TileSource.allCases { TileDiskCache.shared.clear(s) }
        refreshSizes()
        message = "Offline tiles cleared."
    }

    private nonisolated static func fetch(_ r: TileRequest) async -> Bool {
        if TileDiskCache.shared.has(r) { return true }
        guard let url = r.source.url(for: r.tile) else { return false }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else { return false }
            TileDiskCache.shared.write(data, r)
            return true
        } catch {
            return false
        }
    }
}
