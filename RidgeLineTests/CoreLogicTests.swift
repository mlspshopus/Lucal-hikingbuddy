import XCTest
@testable import RidgeLineOverland

final class FuelPlanTests: XCTestCase {
    func testDefaultsMatchSpecInputs() {
        let plan = FuelPlan.ramBloodMountain()
        XCTAssertEqual(plan.miles, 910)
        XCTAssertEqual(plan.mpg, 16.0)
        XCTAssertEqual(plan.price, 3.15)
        XCTAssertEqual(plan.tankGallons, 26)
    }

    func testDefaultMath() {
        let plan = FuelPlan.ramBloodMountain()
        XCTAssertEqual(plan.gallons, 56.875, accuracy: 0.001)
        XCTAssertEqual(plan.tanks, 2.187, accuracy: 0.001)
        XCTAssertEqual(plan.totalCost, 179.15625, accuracy: 0.001)
        XCTAssertEqual(plan.perPerson, 89.578125, accuracy: 0.001)
    }

    func testZeroMpgDoesNotDivideByZero() {
        var plan = FuelPlan()
        plan.mpg = 0
        XCTAssertEqual(plan.gallons, 0)
        XCTAssertEqual(plan.totalCost, 0)
    }

    func testDefaultLegsAddUpToSpec() {
        let trip = Trip.bloodMountain()
        XCTAssertEqual(trip.oneWayMiles, 412)
        XCTAssertEqual(trip.oneWayMinutes, 6 * 60 + 32)
        XCTAssertEqual(Fmt.duration(minutes: trip.oneWayMinutes), "6 hr 32 min")
    }
}

final class TemplateTests: XCTestCase {
    func testSpecCounts() {
        let trip = Trip.bloodMountain()
        XCTAssertGreaterThanOrEqual(trip.gear.count, 18)
        XCTAssertGreaterThanOrEqual(trip.food.count, 12)
        XCTAssertEqual(trip.routes.count, 4)
        XCTAssertEqual(trip.places.filter { $0.kind == .camp }.count, 4)
        XCTAssertEqual(trip.sights.count, 6)
    }

    func testSightsReferenceExistingPlaces() {
        let trip = Trip.bloodMountain()
        for s in trip.sights { XCTAssertNotNil(trip.place(id: s.placeID), s.name) }
        for r in trip.routes { XCTAssertNotNil(r.trailheadID.flatMap { trip.place(id: $0) }, r.name) }
    }

    func testDuplicateResetsProgress() {
        var trip = Trip.bloodMountain()
        trip.gear[0].stage = .packed
        trip.food[0].bought = true
        trip.sights[0].visited = true
        let copy = trip.duplicated(as: "Copy")
        XCTAssertNotEqual(copy.id, trip.id)
        XCTAssertEqual(copy.gear[0].stage, .atHome)
        XCTAssertFalse(copy.food[0].bought)
        XCTAssertFalse(copy.sights[0].visited)
    }

    func testStageCyclesAndLabels() {
        XCTAssertEqual(GearStage.atHome.next, .driveway)
        XCTAssertEqual(GearStage.driveway.next, .packed)
        XCTAssertEqual(GearStage.packed.next, .atHome)
        XCTAssertEqual(GearStage.packed.label(vehicle: "RAM"), "3. In RAM / Pack ✓")
    }

    func testTripRoundTripsThroughJSON() throws {
        var trip = Trip.bloodMountain()
        trip.gear[2].stage = .driveway
        let data = try JSONEncoder().encode(trip)
        let back = try JSONDecoder().decode(Trip.self, from: data)
        XCTAssertEqual(back, trip)
    }
}

final class SolarTests: XCTestCase {
    func testBloodMountainLateOctober() throws {
        let tz = TimeZone(identifier: "America/New_York")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let date = cal.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 12))!
        let t = try XCTUnwrap(SolarCalculator.times(on: date, coord: Coord(34.7398, -83.9378), timeZone: tz))
        let rise = cal.dateComponents([.hour, .minute], from: t.sunrise)
        let set = cal.dateComponents([.hour, .minute], from: t.sunset)
        XCTAssertEqual(rise.hour, 7)
        XCTAssertEqual(Double(rise.minute ?? 0), 53, accuracy: 6)
        XCTAssertEqual(set.hour, 18)
        XCTAssertEqual(Double(set.minute ?? 0), 46, accuracy: 6)
        XCTAssertEqual(t.sunset.timeIntervalSince(t.tentUpBy), 5400, accuracy: 0.5)
    }

    func testPolarNightReturnsNil() {
        let tz = TimeZone(identifier: "UTC")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let date = cal.date(from: DateComponents(year: 2026, month: 12, day: 21, hour: 12))!
        XCTAssertNil(SolarCalculator.times(on: date, coord: Coord(80, 0), timeZone: tz))
    }
}

final class GPXTests: XCTestCase {
    func testParsesTrackAndGain() throws {
        let gpx = """
        <?xml version="1.0"?>
        <gpx version="1.1"><trk><name>Test Hike</name><trkseg>
        <trkpt lat="34.7422" lon="-83.9226"><ele>900</ele></trkpt>
        <trkpt lat="34.7410" lon="-83.9300"><ele>1000</ele></trkpt>
        <trkpt lat="34.7398" lon="-83.9378"><ele>1200</ele></trkpt>
        </trkseg></trk></gpx>
        """
        let track = try XCTUnwrap(GPXParser.parse(Data(gpx.utf8)))
        XCTAssertEqual(track.name, "Test Hike")
        XCTAssertEqual(track.points.count, 3)
        XCTAssertEqual(track.gainFt, Int((300 * 3.28084).rounded()))
        XCTAssertEqual(track.miles, 0.85, accuracy: 0.1)
    }

    func testRejectsTooFewPoints() {
        let gpx = #"<gpx><trk><trkseg><trkpt lat="1" lon="2"/></trkseg></trk></gpx>"#
        XCTAssertNil(GPXParser.parse(Data(gpx.utf8)))
    }
}

final class TilePlannerTests: XCTestCase {
    func testKnownTile() {
        // Standard slippy-map reference: Greenwich at z=1 is tile (1, 1) just SE of the origin.
        XCTAssertEqual(TilePlanner.tileX(lon: 0.1, z: 1), 1)
        XCTAssertEqual(TilePlanner.tileY(lat: -0.1, z: 1), 1)
        XCTAssertEqual(TilePlanner.tileX(lon: -179.9, z: 4), 0)
    }

    func testBoxCountMatchesGeneratedTiles() {
        let g = TilePlanner.Geometry.box(minLat: 34.69, maxLat: 34.80, minLon: -84.00, maxLon: -83.85)
        XCTAssertEqual(TilePlanner.count(g, zooms: 10...14), TilePlanner.tiles(g, zooms: 10...14).count)
    }

    func testCorridorIsMuchSmallerThanItsBoundingBox() {
        let path = Trip.bloodMountain().routes[1].path
        let corridor = TilePlanner.Geometry.corridor(paths: [path], bufferMeters: 1609)
        let box = TilePlanner.box(around: path, pad: 0.1)!
        let zooms = DetailLevel.detailed.zooms
        let c = TilePlanner.count(corridor, zooms: zooms)
        XCTAssertGreaterThan(c, 0)
        XCTAssertLessThan(c, TilePlanner.hardCap)
        XCTAssertGreaterThanOrEqual(TilePlanner.count(box, zooms: zooms) + 400, c)
    }

    func testCorridorCoversEveryPathPoint() {
        let path = Trip.bloodMountain().routes[0].path
        let tiles = Set(TilePlanner.corridorTiles(paths: [path], bufferMeters: 200, zooms: 15...15))
        for p in path {
            XCTAssertTrue(tiles.contains(TilePath(z: 15, x: TilePlanner.tileX(lon: p.lon, z: 15),
                                                  y: TilePlanner.tileY(lat: p.lat, z: 15))))
        }
    }

    func testBiggerBufferNeverShrinks() {
        let path = Trip.bloodMountain().routes[0].path
        let small = TilePlanner.count(.corridor(paths: [path], bufferMeters: 400), zooms: 10...16)
        let big = TilePlanner.count(.corridor(paths: [path], bufferMeters: 3200), zooms: 10...16)
        XCTAssertGreaterThan(big, small)
    }

    func testHugeBoxIsOverTheCap() {
        let g = TilePlanner.Geometry.box(minLat: 25, maxLat: 45, minLon: -100, maxLon: -70)
        XCTAssertGreaterThan(TilePlanner.count(g, zooms: DetailLevel.standard.zooms), TilePlanner.hardCap)
    }

    func testTileSourceURLsAndLimits() {
        XCTAssertEqual(TileSource.allCases.count, 4)
        let t = TilePath(z: 15, x: 8000, y: 12900)
        XCTAssertEqual(TileSource.topo.url(for: t)?.absoluteString,
                       "https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/15/12900/8000")
        XCTAssertTrue(TileSource.aerial.template.contains("USGSImageryOnly"))
        XCTAssertEqual(DetailLevel.detailed.maxZoom, TileSource.maxZoom)
    }
}

final class OpenMeteoTests: XCTestCase {
    func testURLHasRequiredParameters() throws {
        let url = try XCTUnwrap(OpenMeteo.url(for: Coord(34.7398, -83.9378)))
        let s = url.absoluteString
        XCTAssertTrue(s.hasPrefix("https://api.open-meteo.com/v1/forecast"))
        XCTAssertTrue(s.contains("latitude=34.7398"))
        XCTAssertTrue(s.contains("longitude=-83.9378"))
        XCTAssertTrue(s.contains("temperature_unit=fahrenheit"))
        XCTAssertTrue(s.contains("sunrise,sunset"))
        XCTAssertTrue(s.contains("uv_index_max"))
    }

    func testDecodesSampleResponse() throws {
        let json = """
        {"timezone":"America/New_York",
         "current":{"temperature_2m":48.2,"wind_speed_10m":9.4,"weather_code":2},
         "daily":{"time":["2026-10-29","2026-10-30"],
                  "temperature_2m_max":[61.0,58.5],"temperature_2m_min":[38.0,36.2],
                  "sunrise":["2026-10-29T07:52","2026-10-30T07:53"],
                  "sunset":["2026-10-29T18:44","2026-10-30T18:43"],
                  "precipitation_probability_max":[10,null],"uv_index_max":[4.1,3.9]}}
        """
        let f = try OpenMeteo.decode(Data(json.utf8))
        XCTAssertEqual(f.days.count, 2)
        XCTAssertEqual(f.currentTempF, 48.2)
        XCTAssertEqual(f.days[1].rainPercent, 0)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = f.timeZone
        let c = cal.dateComponents([.hour, .minute], from: f.days[0].sunrise)
        XCTAssertEqual(c.hour, 7)
        XCTAssertEqual(c.minute, 52)
        XCTAssertNotNil(f.day(on: f.days[0].sunrise))
    }
}

final class MapsLinkTests: XCTestCase {
    func testAppleLinkUsesAddressQueryAndCoordinates() throws {
        let leg = Trip.bloodMountain().legs[0]
        let url = try XCTUnwrap(MapsLink.apple(from: leg.from, to: leg.to))
        let s = url.absoluteString
        XCTAssertTrue(s.hasPrefix("https://maps.apple.com/"))
        XCTAssertTrue(s.contains("saddr=1505%20Fort%20Clarke%20Blvd"))
        XCTAssertTrue(s.contains("dirflg=d"))
    }

    func testGoogleLinkToCoordinate() throws {
        let last = Trip.bloodMountain().legs[2]
        let url = try XCTUnwrap(MapsLink.google(from: nil, to: last.to))
        let s = url.absoluteString
        XCTAssertTrue(s.contains("api=1"))
        XCTAssertTrue(s.contains("destination=34.74220,-83.92260"))
        XCTAssertTrue(s.contains("travelmode=driving"))
        XCTAssertFalse(s.contains("origin="))
    }
}


final class TrailDiscoveryTests: XCTestCase {
    private let center = Coord(34.7398, -83.9378)

    private func way(_ name: String, _ pts: [(Double, Double)]) -> String {
        let g = pts.map { "{\"lat\":\($0.0),\"lon\":\($0.1)}" }.joined(separator: ",")
        return "{\"type\":\"way\",\"id\":1,\"tags\":{\"highway\":\"path\",\"name\":\"\(name)\"},\"geometry\":[\(g)]}"
    }

    func testStitchesConnectedWaysAndSkipsShortOnes() throws {
        // Two connected ~0.4 mi pieces of one trail (second one stored backwards), plus a tiny stub.
        let a = way("Freeman Trail", [(34.7422, -83.9226), (34.7425, -83.9262), (34.7418, -83.9298)])
        let b = way("Freeman Trail", [(34.7402, -83.9358), (34.7410, -83.9331), (34.7418, -83.9298)])
        let stub = way("Tiny Spur", [(34.7500, -83.9500), (34.7501, -83.9501)])
        let json = "{\"elements\":[\(a),\(b),\(stub)]}"
        let trails = try TrailDiscovery.parse(Data(json.utf8), center: center)
        XCTAssertEqual(trails.count, 1)
        let t = try XCTUnwrap(trails.first)
        XCTAssertEqual(t.name, "Freeman Trail")
        XCTAssertEqual(t.wayCount, 2)
        XCTAssertEqual(t.path.count, 5)
        XCTAssertGreaterThan(t.miles, 0.6)
        XCTAssertLessThan(t.miles, 1.0)
    }

    func testIgnoresUnnamedAndNonWayElements() throws {
        let json = #"{"elements":[{"type":"node","id":1,"lat":1,"lon":2},{"type":"way","id":2,"geometry":[{"lat":1,"lon":2},{"lat":1.1,"lon":2.1}]}]}"#
        XCTAssertTrue(try TrailDiscovery.parse(Data(json.utf8), center: center).isEmpty)
    }

    func testSortsNearestStartFirst() throws {
        let near = way("Near Trail", [(34.7400, -83.9380), (34.7450, -83.9380), (34.7500, -83.9380)])
        let far = way("Far Trail", [(34.8000, -83.9000), (34.8050, -83.9000), (34.8100, -83.9000)])
        let json = "{\"elements\":[\(far),\(near)]}"
        let trails = try TrailDiscovery.parse(Data(json.utf8), center: center)
        XCTAssertEqual(trails.map(\.name), ["Near Trail", "Far Trail"])
    }

    func testQueryAndBodyEncoding() throws {
        let q = TrailDiscovery.query(center: center, radiusMeters: 5000)
        XCTAssertTrue(q.contains("around:5000,34.7398,-83.9378"))
        XCTAssertTrue(q.contains("out geom"))
        let body = String(decoding: try XCTUnwrap(TrailDiscovery.requestBody(q)), as: UTF8.self)
        XCTAssertTrue(body.hasPrefix("data="))
        XCTAssertFalse(body.contains(" "))
        XCTAssertFalse(body.contains("["))
    }

    func testElevationRequestAndParsing() throws {
        let long = (0..<250).map { Coord(34.7 + Double($0) * 0.0001, -83.9) }
        let sampled = TrailDiscovery.samplePoints(long, limit: 100)
        XCTAssertEqual(sampled.count, 100)
        XCTAssertEqual(sampled.first, long.first)
        XCTAssertEqual(sampled.last, long.last)
        let url = try XCTUnwrap(TrailDiscovery.elevationURL(for: Array(sampled.prefix(2))))
        XCTAssertTrue(url.absoluteString.hasPrefix("https://api.open-meteo.com/v1/elevation?"))
        XCTAssertEqual(TrailDiscovery.parseElevations(Data(#"{"elevation":[100.0,150.5]}"#.utf8)), [100.0, 150.5])
        XCTAssertNil(TrailDiscovery.parseElevations(Data("nope".utf8)))
    }

    func testGainsAreDirectional() {
        let g = TrailDiscovery.gains([100, 200, 300, 250, 400])
        XCTAssertEqual(g.forward, Int((350.0 * 3.28084).rounded()))   // +200 m, −50 m, +150 m
        XCTAssertEqual(g.reverse, Int((50.0 * 3.28084).rounded()))    // only the 250 → 300 m step climbs
    }

    func testOutAndBackRouteDoublesDistanceAndClimb() {
        var t = DiscoveredTrail(name: "Test", path: [Coord(34.7, -83.9), Coord(34.71, -83.9)], miles: 2.0,
                                wayCount: 1, startDistanceMiles: 0.5)
        t.gainForwardFt = 800
        t.gainReverseFt = 100
        let oneWay = t.asRoute(outAndBack: false)
        let both = t.asRoute(outAndBack: true)
        XCTAssertEqual(oneWay.miles, 2.0)
        XCTAssertEqual(oneWay.gainFt, 800)
        XCTAssertEqual(both.miles, 4.0)
        XCTAssertEqual(both.gainFt, 900)
        XCTAssertTrue(both.isImported)
        XCTAssertGreaterThan(t.estimatedMinutes(outAndBack: true), t.estimatedMinutes(outAndBack: false))
    }
}

final class HikeMathTests: XCTestCase {
    func testNaismithStyleTime() {
        XCTAssertEqual(HikeMath.minutes(miles: 4, gainFt: 0), 120)
        XCTAssertEqual(HikeMath.minutes(miles: 4.3, gainFt: 1460), Int((4.3 * 30 + 43.8).rounded()))
        XCTAssertGreaterThan(Trip.bloodMountain().routes[0].estimatedMinutes, 120)
    }
}

final class SuggestionTests: XCTestCase {
    func testCatalogsAreRichAndUnique() {
        XCTAssertGreaterThanOrEqual(Suggestions.gear.count, 60)
        XCTAssertGreaterThanOrEqual(Suggestions.food.count, 40)
        XCTAssertEqual(Set(Suggestions.gear.map(\.name)).count, Suggestions.gear.count)
        XCTAssertEqual(Set(Suggestions.food.map(\.name)).count, Suggestions.food.count)
        for s in Suggestions.gear { XCTAssertTrue(Suggestions.gearCategories.contains(s.category), s.name) }
        for s in Suggestions.food { XCTAssertTrue(Suggestions.foodCategories.contains(s.category), s.name) }
    }

    func testGameKitItemsExist() {
        XCTAssertEqual(Suggestions.gameKit.count, Suggestions.gameKitNames.count)
    }
}

final class GamesTests: XCTestCase {
    func testGamesAreCompleteAndMostlyCards() {
        let games = Starter.games()
        XCTAssertGreaterThanOrEqual(games.count, 10)
        XCTAssertGreaterThanOrEqual(games.filter { $0.kind.hasPrefix("Card") }.count, 7)
        XCTAssertEqual(Set(games.map(\.id)).count, games.count)
        for g in games {
            XCTAssertGreaterThanOrEqual(g.rules.count, 3, g.name)
            XCTAssertFalse(g.overview.isEmpty, g.name)
            XCTAssertFalse(g.bring.isEmpty, g.name)
        }
    }
}

final class MigrationTests: XCTestCase {
    func testOlderSavedTripWithoutNewKeysStillLoads() throws {
        // A trip JSON from the first release: no `games`, no food categories.
        var trip = Trip.bloodMountain()
        trip.games = []
        let data = try JSONEncoder().encode(trip)
        var obj = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        obj.removeValue(forKey: "games")
        let old = try JSONSerialization.data(withJSONObject: obj)
        let back = try JSONDecoder().decode(Trip.self, from: old)
        XCTAssertEqual(back.name, trip.name)
        XCTAssertGreaterThanOrEqual(back.games.count, 10)
        XCTAssertEqual(back.gear.count, trip.gear.count)
    }
}
