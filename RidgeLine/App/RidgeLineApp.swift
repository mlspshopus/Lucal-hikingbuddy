import SwiftUI

@main
struct RidgeLineOverlandApp: App {
    @StateObject private var store = TripStore()
    @StateObject private var location = LocationService()
    @StateObject private var network = NetworkMonitor()

    init() {
        Appearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(location)
                .environmentObject(network)
                .preferredColorScheme(.light)   // bright daylight palette only
        }
    }
}
