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

    func testPlanStaysUnderCap() {
        let plan = TilePlanner.plan(minLat: 34.69, maxLat: 34.80, minLon: -84.00, maxLon: -83.85)
        XCTAssertLessThanOrEqual(plan.tiles.count, TilePlanner.maxTiles)
        XCTAssertGreaterThanOrEqual(plan.maxZoom, 13)
        XCTAssertTrue(plan.tiles.allSatisfy { $0.z >= TilePlanner.minZoom && $0.z <= plan.maxZoom })
    }

    func testHugeAreaFallsBackToLowZoomOnly() {
        let plan = TilePlanner.plan(minLat: 25, maxLat: 45, minLon: -100, maxLon: -70)
        XCTAssertLessThanOrEqual(plan.maxZoom, 12)
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
