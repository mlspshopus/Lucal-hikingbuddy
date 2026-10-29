import SwiftUI
import UIKit
import MapKit
import UniformTypeIdentifiers

struct TrailMapView: View {
    private enum Panel: String, CaseIterable, Identifiable {
        case routes = "Hiking Routes"
        case camps = "Free Camps"
        case guide = "Camp Guide"
        var id: String { rawValue }
    }

    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var location: LocationService
    @EnvironmentObject private var network: NetworkMonitor
    @StateObject private var downloader = OfflineDownloader()

    @State private var layer: MapLayer = .topo
    @State private var panel: Panel = .routes
    @State private var proxy = MapProxy()
    @State private var selectedPlace: Place?
    @State private var isFullScreen = false
    @State private var showOffline = false
    @State private var offlineScope: OfflineScope = .visible
    @State private var offlineRegion: MKCoordinateRegion?
    @State private var showDiscovery = false
    @State private var discoveryCenter = Coord(34.7398, -83.9378)
    @State private var showImporter = false
    @State private var importMessage: String?
    @State private var showPinAlert = false
    @State private var pinName = ""
    @Environment(\.openURL) private var openURL

    private var trip: Trip { store.trip }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    mapArea.frame(height: isFullScreen ? geo.size.height : geo.size.height * 0.5)
                    if !isFullScreen {
                        Divider().overlay(RL.border)
                        panelArea
                    }
                }
            }
            .rlScreen()
            .navigationTitle("Trail Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(isFullScreen ? .hidden : .visible, for: .navigationBar)
            .toolbar(isFullScreen ? .hidden : .visible, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        pinName = ""
                        showPinAlert = true
                    } label: {
                        Image(systemName: "mappin.and.ellipse").frame(minWidth: 44, minHeight: 44)
                    }
                    .disabled(location.location == nil)
                    .accessibilityLabel("Pin my current location")
                }
                ToolbarItem(placement: .topBarTrailing) { TripMenuButton() }
            }
            .onAppear { location.start() }
            .animation(.easeInOut(duration: 0.25), value: isFullScreen)
            .alert("Pin Current Location", isPresented: $showPinAlert) {
                TextField("Name (e.g. Our campsite)", text: $pinName)
                Button("Save") { pinCurrentLocation() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Drops a pin at your GPS position — handy for finding the truck again.")
            }
            .sheet(item: $selectedPlace) { place in
                PlaceDetailSheet(place: place)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showOffline) {
                OfflineMapsSheet(downloader: downloader, region: offlineRegion, trip: trip,
                                 initialScope: offlineScope, initialSource: layer.tileSource ?? .topo)
            }
            .sheet(isPresented: $showDiscovery) {
                TrailDiscoverySheet(center: discoveryCenter) { route in
                    store.addRoute(route)
                    proxy.fit(route.path)
                }
            }
            .fileImporter(isPresented: $showImporter,
                          allowedContentTypes: [UTType(filenameExtension: "gpx") ?? .xml, .xml]) { result in
                importGPX(result)
            }
        }
    }

    private func openOffline(_ scope: OfflineScope) {
        offlineScope = scope
        offlineRegion = proxy.visibleRegion
        showOffline = true
    }

    private func openDiscovery() {
        if let r = proxy.visibleRegion {
            discoveryCenter = Coord(r.center.latitude, r.center.longitude)
        } else {
            discoveryCenter = mapCenter
        }
        showDiscovery = true
    }

    // MARK: Map

    private var mapCenter: Coord {
        trip.destination?.coord ?? trip.places.first?.coord ?? Coord(34.7398, -83.9378)
    }

    private var mapArea: some View {
        ZStack(alignment: .top) {
            TopoMapView(layer: layer,
                        places: trip.places,
                        routes: trip.routes,
                        activeRouteID: trip.activeRoute?.id,
                        initialCenter: mapCenter,
                        proxy: proxy,
                        onSelectPlace: { selectedPlace = $0 })
                .ignoresSafeArea(.container, edges: isFullScreen ? .all : [])

            VStack(spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    layerMenu
                    Spacer(minLength: 0)
                    if isFullScreen { fullScreenTripChip }
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) { statusBanners }
                    Spacer(minLength: 0)
                    VStack(spacing: 8) { mapButtons }
                }
                Spacer(minLength: 0)
                if let source = layer.tileSource {
                    Text("\(source.title): \(TileSource.attribution)")
                        .font(RL.font(.caption2, .semibold))
                        .foregroundStyle(RL.ink)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(RL.card.opacity(0.9))
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
        }
    }

    private var layerMenu: some View {
        Menu {
            Section("Saveable for offline") {
                ForEach(MapLayer.allCases.filter(\.worksOffline)) { l in layerButton(l) }
            }
            Section("Needs a connection") {
                ForEach(MapLayer.allCases.filter { !$0.worksOffline }) { l in layerButton(l) }
            }
        } label: {
            Label(layer.title, systemImage: "square.3.layers.3d")
                .font(RL.font(.subheadline, .bold))
                .foregroundStyle(RL.pine)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(RL.card.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RL.border, lineWidth: 1))
        }
        .accessibilityLabel("Map layer: \(layer.title)")
    }

    private func layerButton(_ l: MapLayer) -> some View {
        Button {
            layer = l
        } label: {
            if l == layer {
                Label(l.title, systemImage: "checkmark")
            } else {
                Label(l.title, systemImage: l.symbol)
            }
        }
    }

    /// In full screen the nav bar is hidden, so keep the active trail visible as a small chip.
    @ViewBuilder
    private var fullScreenTripChip: some View {
        if let r = trip.activeRoute {
            VStack(alignment: .trailing, spacing: 2) {
                Text(r.name).font(RL.font(.caption, .bold)).foregroundStyle(RL.ink).lineLimit(1)
                Text(String(format: "%.1f mi · %@", r.miles, Fmt.duration(minutes: r.estimatedMinutes)))
                    .font(RL.font(.caption2, .semibold)).foregroundStyle(RL.blaze)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: 180, alignment: .trailing)
            .background(RL.card.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    @ViewBuilder
    private var mapButtons: some View {
        mapButton(isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                  label: isFullScreen ? "Exit full screen map" : "Full screen map") {
            isFullScreen.toggle()
        }
        mapButton("location.fill", label: "Center on my location") {
            location.start()
            proxy.followUser()
        }
        mapButton("scope", label: "Show active trail") {
            if let r = trip.activeRoute { proxy.fit(r.path) }
        }
        mapButton("arrow.down.circle.fill", label: "Save maps for offline use", tint: RL.blaze) {
            openOffline(.visible)
        }
    }

    private func mapButton(_ symbol: String, label: String, tint: Color = RL.pine, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(RL.card.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RL.border, lineWidth: 1))
        }
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var statusBanners: some View {
        if !network.isOnline {
            banner("Offline · GPS still live · saved maps only", symbol: "wifi.slash", tint: RL.blaze)
        }
        if location.isDenied {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                banner("Location is off — tap to enable the blue dot", symbol: "location.slash.fill", tint: RL.blaze)
            }
        }
        if downloader.isRunning {
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: downloader.progress).tint(RL.pine)
                HStack {
                    Text("Saving maps… \(Int(downloader.progress * 100))%")
                        .font(RL.font(.caption, .semibold)).foregroundStyle(RL.ink)
                    Spacer()
                    Button("Cancel") { downloader.cancel() }
                        .font(RL.font(.caption, .bold)).foregroundStyle(RL.blaze)
                }
            }
            .padding(8)
            .frame(maxWidth: 240)
            .background(RL.card.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else if let msg = downloader.message {
            banner(msg, symbol: "checkmark.circle.fill", tint: RL.pine)
                .onTapGesture { downloader.message = nil }
        }
    }

    private func banner(_ text: String, symbol: String, tint: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(RL.font(.caption, .bold))
            .foregroundStyle(tint)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .frame(maxWidth: 240, alignment: .leading)
            .background(RL.card.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(tint.opacity(0.4), lineWidth: 1))
    }

    // MARK: Panels

    private var panelArea: some View {
        VStack(spacing: 0) {
            Picker("Panel", selection: $panel) {
                ForEach(Panel.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(12)

            ScrollView {
                VStack(spacing: 12) {
                    switch panel {
                    case .routes: routesPanel
                    case .camps: campsPanel
                    case .guide: guidePanel
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
        }
    }

    private var routesPanel: some View {
        VStack(spacing: 12) {
            ForEach(trip.routes) { route in
                routeCard(route)
            }
            if trip.routes.isEmpty {
                Text("No hiking routes yet. Tap Find Trails Near Here or import a GPX file.")
                    .font(RL.font(.subheadline)).foregroundStyle(RL.slate).rlCard()
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: "Add More Trails", symbol: "plus.circle.fill")
                Text("Pan the map to where you want to hike, then search. Finds named trails with their start point, length, climb and estimated time — and adds them to the map.")
                    .font(RL.font(.footnote)).foregroundStyle(RL.slate)
                Button { openDiscovery() } label: { Label("Find Trails Near Here", systemImage: "magnifyingglass") }
                    .buttonStyle(PrimaryButtonStyle())
                if let m = importMessage {
                    Text(m).font(RL.font(.footnote, .semibold)).foregroundStyle(RL.blaze)
                }
                Button { showImporter = true } label: { Label("Import GPX Track", systemImage: "square.and.arrow.down") }
                    .buttonStyle(SecondaryButtonStyle())
            }
            .rlCard()

            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: "Offline Maps", symbol: "arrow.down.circle.fill")
                Text("Save topo, aerial or shaded-relief maps for the whole trip, one trail, or exactly what's on screen — before you lose signal.")
                    .font(RL.font(.footnote)).foregroundStyle(RL.slate)
                Button { openOffline(trip.activeRoute == nil ? .visible : .activeTrail) } label: {
                    Label("Save Maps Offline…", systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: RL.blaze))
                Text("Saved so far: \(ByteCountFormatter.string(fromByteCount: Int64(downloader.totalSavedBytes), countStyle: .file))")
                    .font(RL.font(.footnote)).foregroundStyle(RL.slate)
            }
            .rlCard()

            TrailResourcesCard()
        }
    }

    private func routeCard(_ route: HikeRoute) -> some View {
        let active = route.id == trip.activeRoute?.id
        let startPlace = route.trailheadID.flatMap { trip.place(id: $0) }
        let startEndpoint: Endpoint? = startPlace.map { Endpoint(title: $0.name, query: nil, coord: $0.coord) }
            ?? route.startCoord.map { Endpoint(title: "\(route.name) start", query: nil, coord: $0) }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(route.name).font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                Spacer(minLength: 8)
                if active { Chip(text: "ACTIVE", symbol: "location.north.fill", tint: RL.blaze) }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Chip(text: String(format: "%.1f mi", route.miles), symbol: "ruler")
                    Chip(text: Fmt.duration(minutes: route.estimatedMinutes), symbol: "clock.fill", tint: RL.blaze)
                    Chip(text: route.gainFt > 0 ? "+\(route.gainFt.formatted()) ft" : "Mostly flat", symbol: "arrow.up.right")
                    Chip(text: route.difficulty, symbol: "flame.fill", tint: RL.blaze)
                    Chip(text: route.style, symbol: route.style == "Loop" ? "arrow.triangle.2.circlepath" : "arrow.left.arrow.right")
                }
            }
            if let startPlace {
                Label("Starts at \(startPlace.name)", systemImage: "flag.fill")
                    .font(RL.font(.footnote, .semibold)).foregroundStyle(RL.pine)
            } else if let c = route.startCoord {
                Label("Starts at \(c.label)", systemImage: "flag.fill")
                    .font(RL.font(.footnote, .semibold)).foregroundStyle(RL.pine)
            }
            Text(route.blurb).font(RL.font(.subheadline)).foregroundStyle(RL.slate)
            if route.isSketchPath {
                Label("Line is an approximate sketch — import a GPX for exact navigation.", systemImage: "exclamationmark.triangle.fill")
                    .font(RL.font(.caption, .semibold)).foregroundStyle(RL.blaze)
            }
            HStack(spacing: 10) {
                Button {
                    store.setActiveRoute(route.id)
                    proxy.fit(route.path)
                } label: {
                    Label(active ? "Show on Map" : "Make Active", systemImage: active ? "scope" : "figure.hiking")
                }
                .buttonStyle(PrimaryButtonStyle(tint: active ? RL.pine : RL.blaze))

                if let startEndpoint {
                    DirectionsMenu(to: startEndpoint).frame(maxWidth: .infinity)
                }
            }
            Button {
                store.setActiveRoute(route.id)
                openOffline(.activeTrail)
            } label: {
                Label("Save This Trail Offline", systemImage: "arrow.down.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .rlCard()
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(active ? RL.blaze : .clear, lineWidth: 2))
        .contextMenu {
            if route.isImported {
                Button("Delete Imported Route", role: .destructive) { store.deleteRoute(route.id) }
            }
        }
    }

    private var camps: [Place] { trip.places.filter { $0.kind == .camp } }

    private var campsPanel: some View {
        VStack(spacing: 12) {
            if camps.isEmpty {
                Text("No camps saved for this trip. Use the pin button to drop one at your GPS position.")
                    .font(RL.font(.subheadline)).foregroundStyle(RL.slate).rlCard()
            }
            ForEach(camps) { camp in
                VStack(alignment: .leading, spacing: 8) {
                    Label(camp.name, systemImage: PlaceKind.camp.symbol)
                        .font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                    Text(camp.subtitle).font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.pine)
                    if !camp.notes.isEmpty {
                        Text(camp.notes).font(RL.font(.subheadline)).foregroundStyle(RL.slate)
                    }
                    Text(camp.coord.label).font(RL.font(.caption)).foregroundStyle(RL.slate)
                    HStack(spacing: 10) {
                        Button {
                            proxy.focus(on: camp.coord, meters: 2500)
                        } label: {
                            Label("Show on Map", systemImage: "scope")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        DirectionsMenu(to: Endpoint(title: camp.name, query: nil, coord: camp.coord))
                            .frame(maxWidth: .infinity)
                    }
                }
                .rlCard()
            }
            if !camps.isEmpty {
                Label("Camp locations are planning pins. Confirm each road is open and legal to camp on before you drive up.",
                      systemImage: "info.circle.fill")
                    .font(RL.font(.footnote)).foregroundStyle(RL.slate)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var guidePanel: some View {
        VStack(spacing: 12) {
            if trip.place(id: "byron-reece-th") != nil {
                guideCard("Why not sleep in the Byron Reece lot?", symbol: "moon.zzz.fill", bullets: [
                    "It's a day-use trailhead lot for Blood Mountain, not a campground — treat it as park-and-hike only.",
                    "The Blood Mountain Wilderness has a seasonal bear-canister rule for overnight campers along the AT between Jarrard Gap and Neels Gap (historically March 1 – June 1). Bear-bagging doesn't satisfy it.",
                    "Black bears are active from spring through fall and bulk up in autumn. A truck-bed tent is just fabric — keep every bit of food, trash and scented gear locked in the cab.",
                    "Rules change. Check current regulations with the Chattahoochee-Oconee National Forest (Blue Ridge Ranger District) before you go."
                ])
                guideCard("The four free dispersed roads", symbol: "tent.fill", bullets: [
                    "Tray Mountain Rd (FS 79) / Indian Grave Gap — nearest to the Helen side and the highest, coolest nights.",
                    "Corbin Creek Rd (FS 698) — creekside, but keep well back from the water and camp on high, flat ground.",
                    "Wildcat Creek Rd (FS 26-1) — forested stream pull-offs.",
                    "Upper Chattahoochee River Rd (FS 44) — just north of Helen; the easiest drive and the most popular.",
                    "Open the Free Camps tab to see each pin, then use Directions. These are planning pins from your trip notes — verify road numbers and closures with the Forest Service."
                ])
                guideCard("Clearance notes: 2013 RAM 1500 Crew Cab", symbol: "truck.pickup.side.fill", bullets: [
                    "Roughly 19–21 ft long (depends on bed length) with about 8–9 in of ground clearance. Dry, graded gravel is fine; deep ruts, washouts and creek crossings are not.",
                    "Scout narrow pull-offs on foot before pulling in, and don't back toward a drop-off without a spotter.",
                    "Air down a few PSI on washboard with your deflator, then re-inflate before pavement.",
                    "Use the wheel chocks and leveling blocks — sloped pull-offs make for a bad night's sleep in a bed tent.",
                    "After rain, skip anything you can't see the far end of. A tow strap isn't a recovery plan with no cell service."
                ])
            }
            guideCard("Dispersed camping basics", symbol: "leaf.fill", bullets: [
                "Use an existing, durable site and camp well back from streams and trails (Leave No Trace suggests 200 ft).",
                "Check for fire restrictions; use existing rings and buy firewood locally — don't move it between regions.",
                "There's no water, toilet or trash service. Pack out everything and bury waste in a cat hole 6–8 in deep, 200 ft from water.",
                "Observe the posted stay limit, and tell someone your plan since cell coverage is spotty."
            ])
        }
    }

    private func guideCard(_ title: String, symbol: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: title, symbol: symbol)
            ForEach(Array(bullets.enumerated()), id: \.offset) { _, text in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").font(RL.font(.body, .bold)).foregroundStyle(RL.blaze)
                    Text(text).font(RL.font(.subheadline)).foregroundStyle(RL.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .rlCard()
    }

    // MARK: Actions

    private func pinCurrentLocation() {
        guard let loc = location.location else { return }
        let name = pinName.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addPlace(Place(id: "pin-\(UUID().uuidString)",
                             name: name.isEmpty ? "My pin" : name,
                             subtitle: "Dropped \(Date().formatted(date: .abbreviated, time: .shortened))",
                             kind: .camp,
                             coord: Coord(loc.coordinate.latitude, loc.coordinate.longitude)))
    }

    private func importGPX(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            importMessage = "Couldn't open that file: \(error.localizedDescription)"
        case .success(let url):
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url), let track = GPXParser.parse(data) else {
                importMessage = "That file doesn't contain a usable GPX track."
                return
            }
            // Keep the map snappy: very dense tracks are thinned for drawing (distance/gain use the full track).
            let step = max(1, track.points.count / 1500)
            let thinned = track.points.enumerated().filter { $0.offset % step == 0 || $0.offset == track.points.count - 1 }.map(\.element)
            let route = HikeRoute(id: "gpx-\(UUID().uuidString)",
                                  name: track.name,
                                  miles: (track.miles * 10).rounded() / 10,
                                  gainFt: track.gainFt,
                                  difficulty: "Imported",
                                  style: "GPX track",
                                  blurb: "Imported from \(url.lastPathComponent).",
                                  trailheadID: nil,
                                  path: thinned,
                                  isSketchPath: false,
                                  isImported: true)
            store.addRoute(route)
            importMessage = "Imported “\(track.name)”."
            panel = .routes
            proxy.fit(route.path)
        }
    }
}

// MARK: - Place detail

struct PlaceDetailSheet: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Chip(text: place.kind.title, symbol: place.kind.symbol, tint: RL.color(for: place.kind))
                    Text(place.name).font(RL.font(.title2, .bold)).foregroundStyle(RL.ink)
                    if !place.subtitle.isEmpty {
                        Text(place.subtitle).font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.pine)
                    }
                    if !place.notes.isEmpty {
                        Text(place.notes).font(RL.font(.body)).foregroundStyle(RL.ink)
                    }
                    Text(place.coord.label).font(RL.font(.footnote)).foregroundStyle(RL.slate)
                    DirectionsButtons(from: nil, to: Endpoint(title: place.name, query: nil, coord: place.coord))
                }
                .padding(16)
            }
            .rlScreen()
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.bold) } }
        }
    }
}
