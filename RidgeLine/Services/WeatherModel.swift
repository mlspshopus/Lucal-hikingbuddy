import Foundation
import SwiftUI

/// Loads the Open-Meteo forecast for a coordinate and caches the last good result on disk
/// so the Hub still shows data without signal.
@MainActor
final class WeatherModel: ObservableObject {
    @Published var forecast: Forecast?
    @Published var isLoading = false
    @Published var errorText: String?
    @Published var isShowingCached = false

    private var loadedKey: String?

    func load(for coord: Coord, force: Bool = false) async {
        let key = Self.cacheKey(coord)
        if loadedKey != key {
            // New location: show whatever we saved for it (or nothing) while the fresh request runs.
            forecast = Self.readCache(key)
            isShowingCached = forecast != nil
            errorText = nil
        } else if !force, forecast != nil, !isShowingCached {
            return
        }
        loadedKey = key

        guard let url = OpenMeteo.url(for: coord) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let fresh = try OpenMeteo.decode(data)
            forecast = fresh
            isShowingCached = false
            errorText = nil
            Self.writeCache(fresh, key)
        } catch {
            errorText = forecast == nil
                ? "Couldn't reach Open-Meteo. Sunrise and sunset are still calculated on-device."
                : "Offline — showing the last saved forecast."
            if forecast != nil { isShowingCached = true }
        }
    }

    private static func cacheKey(_ c: Coord) -> String { "forecast.\(String(format: "%.3f,%.3f", c.lat, c.lon))" }

    private static func readCache(_ key: String) -> Forecast? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Forecast.self, from: data)
    }

    private static func writeCache(_ f: Forecast, _ key: String) {
        if let data = try? JSONEncoder().encode(f) { UserDefaults.standard.set(data, forKey: key) }
    }
}
