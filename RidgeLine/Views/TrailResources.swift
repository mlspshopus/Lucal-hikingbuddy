import SwiftUI

/// Where to get detailed trail maps with trailheads, mileage, time and live-location maps.
struct TrailResource: Identifiable {
    let id = UUID()
    let name: String
    let what: String
    let cost: String
    let url: String
    let symbol: String
}

enum TrailResources {
    static let all: [TrailResource] = [
        TrailResource(name: "Forest Service maps (Chattahoochee-Oconee NF)",
                      what: "Official free PDF maps, an interactive visitor map with roads, campgrounds and trails, and Avenza downloads that show your live GPS dot offline.",
                      cost: "Free (Avenza maps may cost a little)",
                      url: "https://www.fs.usda.gov/r08/chattahoochee-oconee/maps-guides", symbol: "tree.fill"),
        TrailResource(name: "AllTrails",
                      what: "Huge trail database with start points, distance, elevation, estimated time, reviews and a live GPS map. Offline maps need the paid plan.",
                      cost: "Free to browse; paid plan for offline maps",
                      url: "https://www.alltrails.com", symbol: "figure.hiking"),
        TrailResource(name: "Gaia GPS",
                      what: "Topo, satellite and Forest Service layers with trail overlays, live location, and downloadable offline maps.",
                      cost: "Free basics; paid for full offline layers",
                      url: "https://www.gaiagps.com", symbol: "location.north.line.fill"),
        TrailResource(name: "onX Backcountry",
                      what: "Trail maps with public and private land boundaries, offline maps and live tracking.",
                      cost: "Paid subscription",
                      url: "https://www.onxmaps.com/backcountry", symbol: "map.fill"),
        TrailResource(name: "FarOut (Appalachian Trail guide)",
                      what: "Mile-by-mile Appalachian Trail guide with water, campsites and a live blue dot. Ideal if you want the AT through Neels Gap.",
                      cost: "Paid per guide",
                      url: "https://faroutguides.com", symbol: "arrow.up.right.circle.fill"),
        TrailResource(name: "CalTopo",
                      what: "Free web map with USGS topo, slope shading and Forest Service layers. Lets you draw a route and export a GPX to import here.",
                      cost: "Free for basic use",
                      url: "https://caltopo.com", symbol: "pencil.and.ruler.fill"),
        TrailResource(name: "Discover Georgia Outdoors",
                      what: "Free trail maps and a trail finder for Georgia state and federal lands.",
                      cost: "Free",
                      url: "https://www.discovergeorgiaoutdoors.com", symbol: "leaf.fill"),
        TrailResource(name: "Waymarked Trails",
                      what: "Shows hiking routes drawn from OpenStreetMap on a web map, with route length and elevation profile.",
                      cost: "Free",
                      url: "https://hiking.waymarkedtrails.org", symbol: "signpost.right.fill")
    ]
}

struct TrailResourcesCard: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Find Trail Maps", symbol: "books.vertical.fill")
            Text("Great places for trailheads, mileage, hiking time and live-location maps. Export a GPX and use Import GPX Track to see it here.")
                .font(RL.font(.footnote)).foregroundStyle(RL.slate)
            ForEach(TrailResources.all) { r in
                VStack(alignment: .leading, spacing: 4) {
                    Divider().overlay(RL.border)
                    Button {
                        if let url = URL(string: r.url) { openURL(url) }
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: r.symbol).foregroundStyle(RL.blaze).frame(width: 26).padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.name).font(RL.font(.subheadline, .bold)).foregroundStyle(RL.pine)
                                    .multilineTextAlignment(.leading)
                                Text(r.what).font(RL.font(.footnote)).foregroundStyle(RL.ink)
                                    .multilineTextAlignment(.leading)
                                Text(r.cost).font(RL.font(.caption, .semibold)).foregroundStyle(RL.slate)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right.square").foregroundStyle(RL.slate)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Divider().overlay(RL.border)
            HStack {
                Image(systemName: "phone.fill").foregroundStyle(RL.blaze)
                Link("Blue Ridge Ranger District: 706-745-6928", destination: URL(string: "tel:7067456928")!)
                    .font(RL.font(.subheadline, .bold)).foregroundStyle(RL.pine)
            }
            .frame(minHeight: 44)
        }
        .rlCard()
    }
}
