import Foundation

enum TrailDiscoveryError: LocalizedError {
    case unreachable
    case noData

    var errorDescription: String? {
        switch self {
        case .unreachable: return "Couldn't reach the OpenStreetMap trail service. Check your signal and try again."
        case .noData: return "The trail service returned something unexpected. Try again in a minute."
        }
    }
}

/// Finds named hiking paths near a point from OpenStreetMap (Overpass API) and estimates climb with Open-Meteo.
/// Both are free and need no API key.
enum TrailDiscoveryService {
    static func search(center: Coord, radiusMeters: Int) async throws -> [DiscoveredTrail] {
        let query = TrailDiscovery.query(center: center, radiusMeters: radiusMeters)
        guard let body = TrailDiscovery.requestBody(query) else { throw TrailDiscoveryError.noData }

        var lastError: Error = TrailDiscoveryError.unreachable
        for endpoint in TrailDiscovery.endpoints {
            guard let url = URL(string: endpoint) else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = body
            request.timeoutInterval = 35
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("RidgeLineOverland/1.0 (iOS hiking planner)", forHTTPHeaderField: "User-Agent")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { continue }
                return try TrailDiscovery.parse(data, center: center)
            } catch {
                lastError = error
            }
        }
        if lastError is DecodingError { throw TrailDiscoveryError.noData }
        throw TrailDiscoveryError.unreachable
    }

    /// Climb in each direction along the trail, or nil if the elevation service is unavailable.
    static func gains(for trail: DiscoveredTrail) async -> (forward: Int, reverse: Int)? {
        let points = TrailDiscovery.samplePoints(trail.path, limit: 100)
        guard let url = TrailDiscovery.elevationURL(for: points) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let elevations = TrailDiscovery.parseElevations(data),
              elevations.count == points.count else { return nil }
        return TrailDiscovery.gains(elevations)
    }
}
