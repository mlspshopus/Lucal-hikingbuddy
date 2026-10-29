import Foundation

/// A decoded Open-Meteo forecast, trimmed to what the app shows. Codable so the last
/// good result can be cached for use when the trail has no signal.
struct Forecast: Codable, Equatable {
    struct Day: Codable, Equatable, Identifiable {
        var date: String              // "yyyy-MM-dd" in the forecast's timezone
        var maxF: Double
        var minF: Double
        var rainPercent: Int
        var uvMax: Double
        var sunrise: Date
        var sunset: Date
        var id: String { date }
    }

    var fetchedAt: Date
    var timeZoneID: String
    var currentTempF: Double
    var windMph: Double
    var weatherCode: Int
    var days: [Day]

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }

    func day(on date: Date) -> Day? {
        let key = Forecast.dayKey(date, in: timeZone)
        return days.first { $0.date == key }
    }

    static func dayKey(_ date: Date, in tz: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = tz
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

enum OpenMeteo {
    static func url(for coord: Coord) -> URL? {
        var c = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        c?.queryItems = [
            URLQueryItem(name: "latitude", value: String(coord.lat)),
            URLQueryItem(name: "longitude", value: String(coord.lon)),
            URLQueryItem(name: "current", value: "temperature_2m,wind_speed_10m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max,uv_index_max"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "16")
        ]
        return c?.url
    }

    private struct Response: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let wind_speed_10m: Double
            let weather_code: Int
        }
        struct Daily: Decodable {
            let time: [String]
            let temperature_2m_max: [Double?]
            let temperature_2m_min: [Double?]
            let sunrise: [String?]
            let sunset: [String?]
            let precipitation_probability_max: [Int?]
            let uv_index_max: [Double?]
        }
        let timezone: String
        let current: Current
        let daily: Daily
    }

    static func decode(_ data: Data, fetchedAt: Date = Date()) throws -> Forecast {
        let r = try JSONDecoder().decode(Response.self, from: data)
        let tz = TimeZone(identifier: r.timezone) ?? .current
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = tz
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"

        var days: [Forecast.Day] = []
        let d = r.daily
        for i in d.time.indices {
            guard i < d.sunrise.count, i < d.sunset.count,
                  let riseStr = d.sunrise[i], let setStr = d.sunset[i],
                  let rise = f.date(from: riseStr), let set = f.date(from: setStr) else { continue }
            days.append(Forecast.Day(
                date: d.time[i],
                maxF: (i < d.temperature_2m_max.count ? d.temperature_2m_max[i] : nil) ?? 0,
                minF: (i < d.temperature_2m_min.count ? d.temperature_2m_min[i] : nil) ?? 0,
                rainPercent: (i < d.precipitation_probability_max.count ? d.precipitation_probability_max[i] : nil) ?? 0,
                uvMax: (i < d.uv_index_max.count ? d.uv_index_max[i] : nil) ?? 0,
                sunrise: rise,
                sunset: set))
        }
        return Forecast(fetchedAt: fetchedAt, timeZoneID: r.timezone,
                        currentTempF: r.current.temperature_2m,
                        windMph: r.current.wind_speed_10m,
                        weatherCode: r.current.weather_code,
                        days: days)
    }
}

/// WMO weather interpretation codes used by Open-Meteo.
enum WMO {
    static func describe(_ code: Int) -> (text: String, symbol: String) {
        switch code {
        case 0: return ("Clear sky", "sun.max.fill")
        case 1: return ("Mostly clear", "sun.max.fill")
        case 2: return ("Partly cloudy", "cloud.sun.fill")
        case 3: return ("Overcast", "cloud.fill")
        case 45, 48: return ("Fog", "cloud.fog.fill")
        case 51, 53, 55, 56, 57: return ("Drizzle", "cloud.drizzle.fill")
        case 61, 63, 65, 66, 67: return ("Rain", "cloud.rain.fill")
        case 71, 73, 75, 77: return ("Snow", "cloud.snow.fill")
        case 80, 81, 82: return ("Rain showers", "cloud.heavyrain.fill")
        case 85, 86: return ("Snow showers", "cloud.snow.fill")
        case 95, 96, 99: return ("Thunderstorm", "cloud.bolt.rain.fill")
        default: return ("Unknown", "questionmark.circle")
        }
    }

    static func uvLabel(_ uv: Double) -> String {
        switch uv {
        case ..<3: return "Low"
        case ..<6: return "Moderate"
        case ..<8: return "High"
        case ..<11: return "Very high"
        default: return "Extreme"
        }
    }
}
