import SwiftUI

struct SectionTitle: View {
    let title: String
    var symbol: String?
    var body: some View {
        HStack(spacing: 8) {
            if let symbol {
                Image(systemName: symbol).foregroundStyle(RL.blaze).accessibilityHidden(true)
            }
            Text(title).font(RL.font(.title3, .bold)).foregroundStyle(RL.ink)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

struct Chip: View {
    let text: String
    var symbol: String?
    var tint: Color = RL.pine
    var body: some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol).font(.caption2.weight(.bold)).accessibilityHidden(true) }
            Text(text).font(RL.font(.caption, .semibold))
        }
        .foregroundStyle(tint)
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }
}

/// Two side-by-side buttons that open turn-by-turn directions in Apple Maps or Google Maps.
struct DirectionsButtons: View {
    let from: Endpoint?
    let to: Endpoint
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if let url = MapsLink.apple(from: from, to: to) { openURL(url) }
            } label: {
                Label("Apple Maps", systemImage: "map.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                if let url = MapsLink.google(from: from, to: to) { openURL(url) }
            } label: {
                Label("Google Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

/// Compact menu variant for list rows.
struct DirectionsMenu: View {
    let to: Endpoint
    @Environment(\.openURL) private var openURL

    var body: some View {
        Menu {
            Button("Apple Maps") { if let u = MapsLink.apple(from: nil, to: to) { openURL(u) } }
            Button("Google Maps") { if let u = MapsLink.google(from: nil, to: to) { openURL(u) } }
        } label: {
            Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                .font(RL.font(.subheadline, .bold))
                .foregroundStyle(RL.pine)
                .frame(minHeight: 44)
        }
    }
}

/// Trip switcher used in every tab's navigation bar.
struct TripMenuButton: View {
    @EnvironmentObject private var store: TripStore
    @State private var showManager = false

    var body: some View {
        Menu {
            ForEach(store.trips) { t in
                Button {
                    store.activeTripID = t.id
                } label: {
                    if t.id == store.activeTripID {
                        Label(t.name, systemImage: "checkmark")
                    } else {
                        Text(t.name)
                    }
                }
            }
            Divider()
            Button { showManager = true } label: { Label("Manage Trips…", systemImage: "suitcase.fill") }
        } label: {
            Image(systemName: "suitcase.rolling.fill")
                .foregroundStyle(RL.pine)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("Switch trip")
        .sheet(isPresented: $showManager) { TripManagerView() }
    }
}

extension Date {
    func timeString(in tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "h:mm a"
        return f.string(from: self)
    }
}
