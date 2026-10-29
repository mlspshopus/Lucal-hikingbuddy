import Foundation

/// Universal-link deep links for turn-by-turn directions. Both open the native app when installed
/// and fall back to the web otherwise.
enum MapsLink {
    static func apple(from: Endpoint?, to: Endpoint) -> URL? {
        var c = URLComponents(string: "https://maps.apple.com/")
        var items: [URLQueryItem] = []
        if let from { items.append(URLQueryItem(name: "saddr", value: from.mapsParam)) }
        items.append(URLQueryItem(name: "daddr", value: to.mapsParam))
        items.append(URLQueryItem(name: "dirflg", value: "d"))
        c?.queryItems = items
        return c?.url
    }

    static func google(from: Endpoint?, to: Endpoint) -> URL? {
        var c = URLComponents(string: "https://www.google.com/maps/dir/")
        var items = [URLQueryItem(name: "api", value: "1")]
        if let from { items.append(URLQueryItem(name: "origin", value: from.mapsParam)) }
        items.append(URLQueryItem(name: "destination", value: to.mapsParam))
        items.append(URLQueryItem(name: "travelmode", value: "driving"))
        c?.queryItems = items
        return c?.url
    }
}
