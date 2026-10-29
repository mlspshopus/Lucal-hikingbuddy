import SwiftUI
import MapKit

enum OfflineScope: String, CaseIterable, Identifiable {
    case visible, activeTrail, allTrails, tripArea

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visible: return "What's on screen"
        case .activeTrail: return "Active trail"
        case .allTrails: return "All my trails"
        case .tripArea: return "Whole trip area"
        }
    }

    var blurb: String {
        switch self {
        case .visible: return "The part of the map you're looking at right now."
        case .activeTrail: return "A corridor along the trail you've made active."
        case .allTrails: return "Corridors along every saved hiking route."
        case .tripArea: return "A box around your trailheads, sights and camps."
        }
    }

    var symbol: String {
        switch self {
        case .visible: return "viewfinder"
        case .activeTrail: return "figure.hiking"
        case .allTrails: return "arrow.triangle.branch"
        case .tripArea: return "square.dashed"
        }
    }

    var usesBuffer: Bool { self == .activeTrail || self == .allTrails }
}

private enum Buffer: String, CaseIterable, Identifiable {
    case half, one, two
    var id: String { rawValue }
    var title: String {
        switch self {
        case .half: return "½ mile"
        case .one: return "1 mile"
        case .two: return "2 miles"
        }
    }
    var meters: Double {
        switch self {
        case .half: return 804.67
        case .one: return 1609.34
        case .two: return 3218.69
        }
    }
}

/// Choose *what* to save (screen, a trail corridor, everything), *how sharp*, and *which layers*.
struct OfflineMapsSheet: View {
    @ObservedObject var downloader: OfflineDownloader
    let region: MKCoordinateRegion?
    let trip: Trip
    let initialScope: OfflineScope
    let initialSource: TileSource

    @Environment(\.dismiss) private var dismiss
    @State private var scope: OfflineScope
    @State private var detail: DetailLevel = .standard
    @State private var buffer: Buffer = .one
    @State private var sources: Set<TileSource>
    @State private var tileCount = 0
    @State private var confirmClear = false

    init(downloader: OfflineDownloader, region: MKCoordinateRegion?, trip: Trip,
         initialScope: OfflineScope, initialSource: TileSource) {
        self.downloader = downloader
        self.region = region
        self.trip = trip
        self.initialScope = initialScope
        self.initialSource = initialSource
        _scope = State(initialValue: initialScope)
        _sources = State(initialValue: [initialSource])
    }

    // MARK: Geometry

    private func geometry(for scope: OfflineScope) -> TilePlanner.Geometry? {
        switch scope {
        case .visible:
            guard let r = region else { return nil }
            return .box(minLat: r.center.latitude - r.span.latitudeDelta / 2,
                        maxLat: r.center.latitude + r.span.latitudeDelta / 2,
                        minLon: r.center.longitude - r.span.longitudeDelta / 2,
                        maxLon: r.center.longitude + r.span.longitudeDelta / 2)
        case .activeTrail:
            guard let path = trip.activeRoute?.path, path.count >= 2 else { return nil }
            return .corridor(paths: [path], bufferMeters: buffer.meters)
        case .allTrails:
            let paths = trip.routes.map(\.path).filter { $0.count >= 2 }
            return paths.isEmpty ? nil : .corridor(paths: paths, bufferMeters: buffer.meters)
        case .tripArea:
            return TilePlanner.box(around: trip.places.filter { $0.kind != .origin }.map(\.coord), pad: 0.1)
        }
    }

    private func recompute() {
        tileCount = geometry(for: scope).map { TilePlanner.count($0, zooms: detail.zooms) } ?? 0
    }

    private var requestCount: Int { tileCount * sources.count }
    private var estimatedMB: Double {
        sources.reduce(0.0) { $0 + Double(tileCount * $1.averageTileBytes) } / 1_000_000
    }
    private var overCap: Bool { requestCount > TilePlanner.hardCap }
    private var canDownload: Bool { tileCount > 0 && !overCap && !sources.isEmpty && !downloader.isRunning }

    private func startDownload() {
        guard let g = geometry(for: scope) else { return }
        let tiles = TilePlanner.tiles(g, zooms: detail.zooms)
        let requests = sources.sorted { $0.rawValue < $1.rawValue }
            .flatMap { s in tiles.map { TileRequest(source: s, tile: $0) } }
        downloader.start(requests)
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    scopeCard
                    if scope.usesBuffer { bufferCard }
                    detailCard
                    layersCard
                    summaryCard
                    storageCard
                }
                .padding(16)
            }
            .rlScreen()
            .navigationTitle("Save Maps Offline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.bold) } }
            .onAppear { recompute() }
            .onChange(of: scope) { _, _ in recompute() }
            .onChange(of: detail) { _, _ in recompute() }
            .onChange(of: buffer) { _, _ in recompute() }
            .confirmationDialog("Delete all saved offline maps?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Delete Offline Maps", role: .destructive) { downloader.clearAll() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var scopeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionTitle(title: "1. What to save", symbol: "scope").padding(.bottom, 6)
            ForEach(Array(OfflineScope.allCases.enumerated()), id: \.element.id) { index, s in
                if index > 0 { Divider().overlay(RL.border) }
                let available = geometry(for: s) != nil
                Button { scope = s } label: {
                    HStack(spacing: 12) {
                        Image(systemName: scope == s ? "largecircle.fill.circle" : "circle")
                            .font(.title3).foregroundStyle(scope == s ? RL.pine : RL.slate)
                        VStack(alignment: .leading, spacing: 2) {
                            Label(s.title, systemImage: s.symbol)
                                .font(RL.font(.body, .semibold)).foregroundStyle(RL.ink)
                            Text(available ? s.blurb : "Not available yet for this trip.")
                                .font(RL.font(.footnote)).foregroundStyle(RL.slate)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!available)
                .opacity(available ? 1 : 0.5)
            }
        }
        .rlCard()
    }

    private var bufferCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "How far from the trail?", symbol: "arrow.left.and.right")
            Picker("Distance either side of the trail", selection: $buffer) {
                ForEach(Buffer.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Text("Wider keeps you covered if you wander off-route or need to bail out to a road.")
                .font(RL.font(.footnote)).foregroundStyle(RL.slate)
        }
        .rlCard()
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "2. How sharp?", symbol: "plus.magnifyingglass")
            Picker("Detail", selection: $detail) {
                ForEach(DetailLevel.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Text(detail.blurb).font(RL.font(.footnote)).foregroundStyle(RL.slate)
        }
        .rlCard()
    }

    private var layersCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionTitle(title: "3. Which layers?", symbol: "square.3.layers.3d").padding(.bottom, 6)
            ForEach(Array(TileSource.allCases.enumerated()), id: \.element.id) { index, s in
                if index > 0 { Divider().overlay(RL.border) }
                Button {
                    if sources.contains(s) {
                        if sources.count > 1 { sources.remove(s) }
                    } else {
                        sources.insert(s)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: sources.contains(s) ? "checkmark.square.fill" : "square")
                            .font(.title3).foregroundStyle(sources.contains(s) ? RL.pine : RL.slate)
                        VStack(alignment: .leading, spacing: 2) {
                            Label(s.title, systemImage: s.symbol)
                                .font(RL.font(.body, .semibold)).foregroundStyle(RL.ink)
                            Text(s.blurb).font(RL.font(.footnote)).foregroundStyle(RL.slate)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Text("Apple Satellite and Hybrid need a connection and can't be saved.")
                .font(RL.font(.footnote)).foregroundStyle(RL.slate).padding(.top, 6)
        }
        .rlCard()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Chip(text: "\(requestCount.formatted()) tiles", symbol: "square.grid.3x3.fill")
                Chip(text: "~\(max(1, Int(estimatedMB.rounded()))) MB", symbol: "internaldrive.fill", tint: RL.blaze)
            }
            if overCap {
                Label("That's more than the \(TilePlanner.hardCap.formatted())-tile limit. Choose a smaller area, less detail, or fewer layers.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(RL.font(.footnote, .semibold)).foregroundStyle(RL.blaze)
            } else if tileCount == 0 {
                Text("Nothing to save for this choice.").font(RL.font(.footnote)).foregroundStyle(RL.slate)
            }

            if downloader.isRunning {
                ProgressView(value: downloader.progress).tint(RL.pine)
                HStack {
                    Text("Saving… \(Int(downloader.progress * 100))%")
                        .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.ink)
                    Spacer()
                    Button("Cancel") { downloader.cancel() }
                        .font(RL.font(.subheadline, .bold)).foregroundStyle(RL.blaze)
                }
            } else {
                Button { startDownload() } label: { Label("Save to This Device", systemImage: "arrow.down.circle.fill") }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canDownload)
                    .opacity(canDownload ? 1 : 0.5)
            }
            if let msg = downloader.message {
                Text(msg).font(RL.font(.footnote, .semibold)).foregroundStyle(RL.pine)
            }
            Text("Downloads need a connection — do this at home or in town. Maps are from USGS The National Map (public domain).")
                .font(RL.font(.caption)).foregroundStyle(RL.slate)
        }
        .rlCard()
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Saved on this device", symbol: "internaldrive")
            ForEach(TileSource.allCases) { s in
                HStack {
                    Text(s.title).font(RL.font(.subheadline)).foregroundStyle(RL.ink)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(downloader.savedBytes[s] ?? 0), countStyle: .file))
                        .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.slate)
                }
            }
            if downloader.totalSavedBytes > 0 {
                Button("Delete All Offline Maps", role: .destructive) { confirmClear = true }
                    .font(RL.font(.footnote, .bold))
            }
        }
        .rlCard()
    }
}
