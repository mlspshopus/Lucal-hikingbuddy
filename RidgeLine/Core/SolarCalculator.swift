import Foundation

struct SunTimes: Equatable {
    let sunrise: Date
    let sunset: Date

    /// Evening golden hour begins about an hour before sunset.
    var eveningGoldenStart: Date { sunset.addingTimeInterval(-3600) }
    /// Morning golden hour ends about an hour after sunrise.
    var morningGoldenEnd: Date { sunrise.addingTimeInterval(3600) }
    /// Target for having the bed tent fully set up: 90 min of light to spare.
    var tentUpBy: Date { sunset.addingTimeInterval(-90 * 60) }
}

/// Offline sunrise/sunset (NOAA general solar position approximation, ±~3 min).
/// Used when Open-Meteo can't be reached so the daylight card still works on the trail.
enum SolarCalculator {
    static func times(on date: Date, coord: Coord, timeZone: TimeZone) -> SunTimes? {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = timeZone
        let ymd = local.dateComponents([.year, .month, .day], from: date)
        guard let year = ymd.year, let month = ymd.month, let day = ymd.day,
              let dayOfYear = local.ordinality(of: .day, in: .year, for: date) else { return nil }

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? timeZone
        guard let utcMidnight = utc.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }

        let g = 2 * Double.pi / 365.0 * Double(dayOfYear - 1)
        let eqTime = 229.18 * (0.000075
            + 0.001868 * cos(g) - 0.032077 * sin(g)
            - 0.014615 * cos(2 * g) - 0.040849 * sin(2 * g))
        let decl = 0.006918
            - 0.399912 * cos(g) + 0.070257 * sin(g)
            - 0.006758 * cos(2 * g) + 0.000907 * sin(2 * g)
            - 0.002697 * cos(3 * g) + 0.00148 * sin(3 * g)

        let lat = coord.lat * Double.pi / 180
        let cosHA = cos(90.833 * Double.pi / 180) / (cos(lat) * cos(decl)) - tan(lat) * tan(decl)
        // Polar day / night: no sunrise or sunset.
        guard cosHA >= -1, cosHA <= 1 else { return nil }
        let ha = acos(cosHA) * 180 / Double.pi

        let riseMin = 720 - 4 * (coord.lon + ha) - eqTime
        let setMin = 720 - 4 * (coord.lon - ha) - eqTime
        return SunTimes(sunrise: utcMidnight.addingTimeInterval(riseMin * 60),
                        sunset: utcMidnight.addingTimeInterval(setMin * 60))
    }
}
