import SwiftUI

/// "Trails near here": named footpaths from OpenStreetMap with start point, distance, climb and estimated hiking time.
struct TrailDiscoverySheet: View {
    let center: Coord
    let onAdd: (HikeRoute) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var radiusKm = 5
    @State private var trails: [DiscoveredTrail] = []
    @State private var isLoading = false
    @State private var isEstimating = false
    @State private var errorText: String?
    @State private var hasSearched = false
    @State private var added: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "Search around the map center", symbol: "scope")
                        Picker("Radius", selection: $radiusKm) {
                            Text("2 km").tag(2)
                            Text("5 km").tag(5)
                            Text("10 km").tag(10)
                        }
                        .pickerStyle(.segmented)
                        Text("Finds named foot trails with a start point, length, estimated climb and hiking time. Pan the map first to search somewhere else.")
                            .font(RL.font(.footnote)).foregroundStyle(RL.slate)
                    }
                    .rlCard()

                    if isLoading {
                        HStack(spacing: 10) {
                            ProgressView().tint(RL.pine)
                            Text("Searching OpenStreetMap…").font(RL.font(.subheadline)).foregroundStyle(RL.slate)
                        }
                        .rlCard()
                    }

                    if let errorText {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(errorText, systemImage: "wifi.exclamationmark")
                                .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.blaze)
                            Button { Task { await search() } } label: { Label("Try Again", systemImage: "arrow.clockwise") }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                        .rlCard()
                    } else if hasSearched && trails.isEmpty && !isLoading {
                        Text("No named trails found within \(radiusKm) km. Try a bigger radius or move the map.")
                            .font(RL.font(.subheadline)).foregroundStyle(RL.slate).rlCard()
                    }

                    ForEach(trails) { trail in trailCard(trail) }

                    Text("Trail data © OpenStreetMap contributors (ODbL). Climb is estimated from Open-Meteo elevation data. Times assume a casual pace of 2 mph plus 30 minutes per 1,000 ft climbed. Always confirm with an official map.")
                        .font(RL.font(.caption)).foregroundStyle(RL.slate)
                        .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .rlScreen()
            .navigationTitle("Trails Near Here")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.bold) } }
            .task { await search() }
            .onChange(of: radiusKm) { _, _ in Task { await search() } }
        }
    }

    private func trailCard(_ trail: DiscoveredTrail) -> some View {
        let isAdded = added.contains(trail.id)
        return VStack(alignment: .leading, spacing: 10) {
            Text(trail.name).font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Chip(text: String(format: "%.1f mi one way", trail.miles), symbol: "ruler")
                    Chip(text: String(format: "Starts %.1f mi away", trail.startDistanceMiles), symbol: "mappin.circle.fill", tint: RL.blaze)
                    if let gain = trail.gainForwardFt {
                        Chip(text: "+\(gain.formatted()) ft", symbol: "arrow.up.right")
                    } else if isEstimating {
                        Chip(text: "Estimating climb…", symbol: "hourglass")
                    }
                }
            }
            if trail.gainForwardFt != nil {
                let one = Fmt.duration(minutes: trail.estimatedMinutes(outAndBack: false))
                let both = Fmt.duration(minutes: trail.estimatedMinutes(outAndBack: true))
                Text("About \(one) one way · \(both) out and back")
                    .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.pine)
            }
            Text("Start: \(trail.start.label)").font(RL.font(.caption)).foregroundStyle(RL.slate)

            if isAdded {
                Label("Added to your routes", systemImage: "checkmark.circle.fill")
                    .font(RL.font(.subheadline, .bold)).foregroundStyle(RL.pine)
            } else {
                HStack(spacing: 10) {
                    Button {
                        add(trail, outAndBack: false)
                    } label: { Label("Add One Way", systemImage: "plus") }
                        .buttonStyle(SecondaryButtonStyle())
                    Button {
                        add(trail, outAndBack: true)
                    } label: { Label("Out & Back", systemImage: "plus") }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .rlCard()
    }

    private func add(_ trail: DiscoveredTrail, outAndBack: Bool) {
        onAdd(trail.asRoute(outAndBack: outAndBack))
        added.insert(trail.id)
    }

    private func search() async {
        isLoading = true
        errorText = nil
        trails = []
        do {
            let found = try await TrailDiscoveryService.search(center: center, radiusMeters: radiusKm * 1000)
            trails = Array(found.prefix(40))
            hasSearched = true
            isLoading = false
            await loadClimbs()
        } catch {
            isLoading = false
            errorText = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Try again."
        }
    }

    private func loadClimbs() async {
        isEstimating = true
        defer { isEstimating = false }
        let snapshot = Array(trails.prefix(25))
        await withTaskGroup(of: (String, Int, Int)?.self) { group in
            for t in snapshot {
                group.addTask {
                    guard let g = await TrailDiscoveryService.gains(for: t) else { return nil }
                    return (t.id, g.forward, g.reverse)
                }
            }
            for await result in group {
                guard let (id, fwd, rev) = result, let i = trails.firstIndex(where: { $0.id == id }) else { continue }
                trails[i].gainForwardFt = fwd
                trails[i].gainReverseFt = rev
            }
        }
    }
}
