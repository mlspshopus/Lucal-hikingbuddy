import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TripStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TripHubView()
                .tabItem { Label("Trip Hub", systemImage: "mountain.2.fill") }
            TrailMapView()
                .tabItem { Label("Trail Map", systemImage: "map.fill") }
            FuelView()
                .tabItem { Label("Fuel", systemImage: "fuelpump.fill") }
            ChecklistView()
                .tabItem { Label("Checklists", systemImage: "checklist") }
        }
        .tint(RL.pine)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.saveNow() }
        }
    }
}
