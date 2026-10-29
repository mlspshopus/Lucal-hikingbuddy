import Foundation

// MARK: - Geometry

struct Coord: Codable, Hashable {
    var lat: Double
    var lon: Double

    init(_ lat: Double, _ lon: Double) {
        self.lat = lat
        self.lon = lon
    }

    /// "34.7398, -83.9378" — for display.
    var label: String { String(format: "%.4f, %.4f", lat, lon) }

    /// "34.73980,-83.93780" — for map deep links.
    var linkParam: String { String(format: "%.5f,%.5f", lat, lon) }
}

// MARK: - Places & routes

enum PlaceKind: String, Codable, CaseIterable {
    case origin, trailhead, summit, landmark, camp, town

    var title: String {
        switch self {
        case .origin: return "Start"
        case .trailhead: return "Trailhead"
        case .summit: return "Summit"
        case .landmark: return "Sight"
        case .camp: return "Free Camp"
        case .town: return "Town"
        }
    }

    var symbol: String {
        switch self {
        case .origin: return "house.fill"
        case .trailhead: return "figure.hiking"
        case .summit: return "mountain.2.fill"
        case .landmark: return "star.fill"
        case .camp: return "tent.fill"
        case .town: return "building.2.fill"
        }
    }
}

struct Place: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var subtitle: String
    var kind: PlaceKind
    var coord: Coord
    var notes: String = ""
}

struct HikeRoute: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var miles: Double
    var gainFt: Int
    var difficulty: String
    var style: String            // "Loop" / "Out & back"
    var blurb: String
    var trailheadID: String?
    var path: [Coord]
    /// True when `path` is a hand-placed sketch between known waypoints rather than surveyed GPX.
    var isSketchPath: Bool = true
    var isImported: Bool = false
}

// MARK: - Driving directions

struct Endpoint: Codable, Hashable {
    var title: String
    /// Free-text query for Maps (address / business). Preferred over `coord` when present.
    var query: String?
    var coord: Coord?

    /// The value passed to Apple/Google Maps as an origin or destination.
    var mapsParam: String {
        if let query, !query.isEmpty { return query }
        if let coord { return coord.linkParam }
        return title
    }
}

struct RouteLeg: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var roads: String
    var miles: Int
    var minutes: Int
    var from: Endpoint
    var to: Endpoint
}

// MARK: - Sights

struct Sight: Identifiable, Codable, Hashable {
    var id: String
    var placeID: String
    var name: String
    var blurb: String
    var symbol: String
    var visited: Bool = false
}

// MARK: - Checklists

enum GearStage: Int, CaseIterable, Codable {
    case atHome = 0, driveway = 1, packed = 2

    func label(vehicle: String) -> String {
        switch self {
        case .atHome: return "1. At Home"
        case .driveway: return "2. Driveway Staged"
        case .packed: return "3. In \(vehicle) / Pack ✓"
        }
    }

    var next: GearStage { GearStage(rawValue: (rawValue + 1) % 3) ?? .atHome }
}

struct GearItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var detail: String
    var category: String
    var stageRaw: Int = 0

    var stage: GearStage {
        get { GearStage(rawValue: stageRaw) ?? .atHome }
        set { stageRaw = newValue.rawValue }
    }
}

struct FoodItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var detail: String
    var estCost: Double
    var bought: Bool = false
    var category: String?
}

struct GameItem: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var kind: String          // "Card game", "Dice game", "Tile game", "No props"
    var players: String
    var minutes: Int
    var bring: String
    var overview: String
    var rules: [String]
    var tip: String
    var packed: Bool = false
}

// MARK: - Fuel

struct PitStop: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var detail: String
    /// Approximate one-way road mile from the origin.
    var mile: Int
}

struct FuelPlan: Codable, Hashable {
    var miles: Double = 910
    var mpg: Double = 16.0
    var price: Double = 3.15
    var tankGallons: Double = 26
    var travelers: Int = 2
    var stops: [PitStop] = []
    var breakdownNote: String = ""

    static let milesRange: ClosedRange<Double> = 100...1600
    static let mpgRange: ClosedRange<Double> = 12...21
    static let priceRange: ClosedRange<Double> = 2.00...5.00

    var gallons: Double { mpg > 0 ? miles / mpg : 0 }
    var tanks: Double { tankGallons > 0 ? gallons / tankGallons : 0 }
    var totalCost: Double { gallons * price }
    var perPerson: Double { totalCost / Double(max(travelers, 1)) }
    var rangePerTank: Double { tankGallons * mpg }

    /// Gallons burned over `miles` of driving at the current MPG.
    func gallons(forMiles m: Double) -> Double { mpg > 0 ? m / mpg : 0 }
}

// MARK: - Trip

struct Trip: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var subtitle: String
    var vehicle: String
    var vehicleShort: String
    var tripDate: Date = Date()
    /// IANA zone of the destination, used for the offline sunrise/sunset fallback.
    var timeZoneID: String?
    var origin: Place?
    var destination: Place?
    var places: [Place] = []
    var routes: [HikeRoute] = []
    var activeRouteID: String?
    var legs: [RouteLeg] = []
    var sights: [Sight] = []
    var gear: [GearItem] = []
    var food: [FoodItem] = []
    var fuel = FuelPlan()
    var games: [GameItem] = []

    var oneWayMiles: Int { legs.reduce(0) { $0 + $1.miles } }
    var oneWayMinutes: Int { legs.reduce(0) { $0 + $1.minutes } }

    var gearCategories: [String] {
        var seen = Set<String>()
        return gear.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }

    func place(id: String) -> Place? { places.first { $0.id == id } }

    var activeRoute: HikeRoute? {
        routes.first { $0.id == activeRouteID } ?? routes.first
    }
}

// Trips saved by older versions lack newer keys, so decode everything leniently.
extension Trip {
    enum CodingKeys: String, CodingKey {
        case id, name, subtitle, vehicle, vehicleShort, tripDate, timeZoneID, origin, destination
        case places, routes, activeRouteID, legs, sights, gear, food, fuel, games
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
        vehicle = try c.decodeIfPresent(String.self, forKey: .vehicle) ?? "Truck"
        vehicleShort = try c.decodeIfPresent(String.self, forKey: .vehicleShort) ?? "Truck"
        tripDate = try c.decodeIfPresent(Date.self, forKey: .tripDate) ?? Date()
        timeZoneID = try c.decodeIfPresent(String.self, forKey: .timeZoneID)
        origin = try c.decodeIfPresent(Place.self, forKey: .origin)
        destination = try c.decodeIfPresent(Place.self, forKey: .destination)
        places = try c.decodeIfPresent([Place].self, forKey: .places) ?? []
        routes = try c.decodeIfPresent([HikeRoute].self, forKey: .routes) ?? []
        activeRouteID = try c.decodeIfPresent(String.self, forKey: .activeRouteID)
        legs = try c.decodeIfPresent([RouteLeg].self, forKey: .legs) ?? []
        sights = try c.decodeIfPresent([Sight].self, forKey: .sights) ?? []
        gear = try c.decodeIfPresent([GearItem].self, forKey: .gear) ?? []
        food = try c.decodeIfPresent([FoodItem].self, forKey: .food) ?? []
        fuel = try c.decodeIfPresent(FuelPlan.self, forKey: .fuel) ?? FuelPlan()
        games = try c.decodeIfPresent([GameItem].self, forKey: .games) ?? Starter.games()
    }
}

// MARK: - Formatting

enum Fmt {
    static func usd(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: v)) ?? String(format: "$%.2f", v)
    }

    static func duration(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m) min" }
        return "\(h) hr \(m) min"
    }
}

// MARK: - Hike math

enum HikeMath {
    /// Casual pace: 2 mph plus 30 minutes for every 1,000 ft climbed (a conservative Naismith's rule).
    static func minutes(miles: Double, gainFt: Int) -> Int {
        Int((miles / 2.0 * 60 + Double(gainFt) / 1000 * 30).rounded())
    }

    /// Cumulative climb in feet. Ignores ±1 m jitter so sensor noise doesn't inflate the number.
    static func gainFt(elevationsMeters e: [Double]) -> Int {
        guard e.count > 1 else { return 0 }
        var gain = 0.0
        var anchor = e[0]
        for v in e.dropFirst() {
            if v - anchor > 1 { gain += v - anchor; anchor = v }
            else if anchor - v > 1 { anchor = v }
        }
        return Int((gain * 3.28084).rounded())
    }
}

extension HikeRoute {
    var estimatedMinutes: Int { HikeMath.minutes(miles: miles, gainFt: gainFt) }
    var startCoord: Coord? { path.first }
}
