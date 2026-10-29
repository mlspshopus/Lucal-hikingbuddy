import SwiftUI

struct TripHubView: View {
    @EnvironmentObject private var store: TripStore
    @StateObject private var weather = WeatherModel()

    private var trip: Trip { store.trip }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if trip.destination == nil { SetDestinationCard() }
                    if !trip.legs.isEmpty { routeCard }
                    if trip.destination != nil {
                        daylightCard
                        weatherCard
                    }
                    if !trip.sights.isEmpty { sightsCard }
                }
                .padding(16)
            }
            .rlScreen()
            .navigationTitle("Trip Hub")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { TripMenuButton() } }
            .task(id: trip.destination?.coord) {
                if let c = trip.destination?.coord { await weather.load(for: c) }
            }
            .refreshable {
                if let c = trip.destination?.coord { await weather.load(for: c, force: true) }
            }
        }
    }

    // MARK: Header

    private var headerCard: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let lower = min(Calendar.current.startOfDay(for: trip.tripDate), today)
        let upper = Calendar.current.date(byAdding: .day, value: 15, to: today) ?? today
        return VStack(alignment: .leading, spacing: 12) {
            Text(trip.name).font(RL.font(.title2, .bold)).foregroundStyle(RL.ink)
            Text(trip.subtitle).font(RL.font(.subheadline)).foregroundStyle(RL.slate)
            HStack(spacing: 8) {
                Chip(text: trip.vehicle, symbol: "truck.pickup.side.fill")
                Chip(text: "\(trip.fuel.travelers) travelers", symbol: "person.2.fill", tint: RL.blaze)
            }
            DatePicker("Trip day", selection: $store.trip.tripDate, in: lower...upper, displayedComponents: .date)
                .font(RL.font(.subheadline, .semibold))
                .foregroundStyle(RL.ink)
                .tint(RL.pine)
        }
        .rlCard()
    }

    // MARK: Route

    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Route to the Trailhead", symbol: "road.lanes")
            HStack(spacing: 8) {
                Chip(text: "\(trip.oneWayMiles) mi one-way", symbol: "arrow.right")
                Chip(text: Fmt.duration(minutes: trip.oneWayMinutes), symbol: "clock.fill", tint: RL.blaze)
            }
            Text("Distances and times are planning estimates; Maps will use live traffic.")
                .font(RL.font(.footnote)).foregroundStyle(RL.slate)

            ForEach(trip.legs) { leg in
                VStack(alignment: .leading, spacing: 8) {
                    Divider().overlay(RL.border)
                    Text(leg.title).font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                    Text("\(leg.roads) · \(leg.miles) mi · \(Fmt.duration(minutes: leg.minutes))")
                        .font(RL.font(.subheadline)).foregroundStyle(RL.slate)
                    DirectionsButtons(from: leg.from, to: leg.to)
                }
            }

            if let first = trip.legs.first, let last = trip.legs.last, trip.legs.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().overlay(RL.border)
                    Text("Whole trip, door to trailhead").font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                    DirectionsButtons(from: first.from, to: last.to)
                }
            }
        }
        .rlCard()
    }

    // MARK: Daylight

    private var timeZone: TimeZone {
        weather.forecast?.timeZone ?? trip.timeZoneID.flatMap(TimeZone.init(identifier:)) ?? .current
    }

    private var sunTimes: (times: SunTimes, isLive: Bool)? {
        if let f = weather.forecast, let d = f.day(on: trip.tripDate) {
            return (SunTimes(sunrise: d.sunrise, sunset: d.sunset), true)
        }
        guard let coord = trip.destination?.coord,
              let t = SolarCalculator.times(on: trip.tripDate, coord: coord, timeZone: timeZone) else { return nil }
        return (t, false)
    }

    private var daylightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Arrival & Daylight Window", symbol: "sun.horizon.fill")
            if let (t, isLive) = sunTimes {
                HStack(spacing: 12) {
                    sunTile(title: "Sunrise", symbol: "sunrise.fill", time: t.sunrise)
                    sunTile(title: "Sunset", symbol: "sunset.fill", time: t.sunset)
                }
                VStack(alignment: .leading, spacing: 6) {
                    infoRow("Set up the bed tent by", t.tentUpBy.timeString(in: timeZone), RL.blaze)
                    infoRow("Morning golden hour",
                            "\(t.sunrise.timeString(in: timeZone)) – \(t.morningGoldenEnd.timeString(in: timeZone))", RL.ink)
                    infoRow("Evening golden hour",
                            "\(t.eveningGoldenStart.timeString(in: timeZone)) – \(t.sunset.timeString(in: timeZone))", RL.ink)
                }
                if Calendar.current.isDateInToday(trip.tripDate), t.sunset > Date() {
                    HStack(spacing: 4) {
                        Text("Sunset in").foregroundStyle(RL.slate)
                        Text(t.sunset, style: .relative).foregroundStyle(RL.blaze).fontWeight(.bold)
                    }
                    .font(RL.font(.subheadline))
                }
                Text(isLive ? "Live from Open-Meteo" : "Calculated on-device (no forecast available)")
                    .font(RL.font(.caption)).foregroundStyle(RL.slate)
            } else {
                Text("Daylight times unavailable for this location.")
                    .font(RL.font(.subheadline)).foregroundStyle(RL.slate)
            }
        }
        .rlCard()
    }

    private func sunTile(title: String, symbol: String, time: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(RL.font(.footnote, .semibold)).foregroundStyle(RL.blaze)
            Text(time.timeString(in: timeZone))
                .font(RL.font(.title2, .bold)).foregroundStyle(RL.ink)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RL.blazeTint)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func infoRow(_ label: String, _ value: String, _ valueColor: Color) -> some View {
        HStack {
            Text(label).font(RL.font(.subheadline)).foregroundStyle(RL.slate)
            Spacer(minLength: 8)
            Text(value).font(RL.font(.subheadline, .bold)).foregroundStyle(valueColor)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Weather

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(title: "Mountain Forecast", symbol: "cloud.sun.fill")
                Spacer()
                if weather.isLoading { ProgressView().tint(RL.pine) }
            }
            if let f = weather.forecast {
                let day = f.day(on: trip.tripDate)
                let isToday = Calendar.current.isDateInToday(trip.tripDate)
                let info = WMO.describe(f.weatherCode)
                if isToday {
                    HStack(spacing: 14) {
                        Image(systemName: info.symbol)
                            .font(.system(size: 40))
                            .symbolRenderingMode(.multicolor)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(f.currentTempF.rounded()))°F now")
                                .font(RL.font(.title, .bold)).foregroundStyle(RL.ink)
                            Text("\(info.text) · wind \(Int(f.windMph.rounded())) mph")
                                .font(RL.font(.subheadline)).foregroundStyle(RL.slate)
                        }
                    }
                }
                if let d = day {
                    HStack(spacing: 8) {
                        Chip(text: "High \(Int(d.maxF.rounded()))°", symbol: "thermometer.high")
                        Chip(text: "Low \(Int(d.minF.rounded()))°", symbol: "thermometer.low", tint: RL.blaze)
                        Chip(text: "Rain \(d.rainPercent)%", symbol: "umbrella.fill")
                    }
                    Text("UV index \(Int(d.uvMax.rounded())) (\(WMO.uvLabel(d.uvMax))) — sunscreen on the open summit.")
                        .font(RL.font(.subheadline)).foregroundStyle(RL.slate)
                    if d.minF <= 40 {
                        Label("Low of \(Int(d.minF.rounded()))°F — bring the 20°F bags and extra blankets.",
                              systemImage: "snowflake")
                            .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.blaze)
                    }
                } else {
                    Text("No forecast for this date yet — forecasts cover the next 16 days.")
                        .font(RL.font(.subheadline)).foregroundStyle(RL.slate)
                }

                outlook(f)

                Text(weather.isShowingCached
                     ? "Saved forecast from \(f.fetchedAt.formatted(date: .abbreviated, time: .shortened))"
                     : "Live from Open-Meteo · summit conditions run colder and windier than the valley")
                    .font(RL.font(.caption)).foregroundStyle(RL.slate)
            } else if weather.isLoading {
                Text("Loading forecast…").font(RL.font(.subheadline)).foregroundStyle(RL.slate)
            }
            if let err = weather.errorText {
                Text(err).font(RL.font(.footnote)).foregroundStyle(RL.blaze)
            }
        }
        .rlCard()
    }

    private func outlook(_ f: Forecast) -> some View {
        let key = Forecast.dayKey(trip.tripDate, in: f.timeZone)
        let start = f.days.firstIndex { $0.date >= key } ?? 0
        let days = Array(f.days.dropFirst(start).prefix(5))
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days) { d in
                    VStack(spacing: 4) {
                        Text(Self.weekday(d.sunrise, f.timeZone))
                            .font(RL.font(.caption, .bold)).foregroundStyle(RL.slate)
                        Text("\(Int(d.maxF.rounded()))°")
                            .font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                        Text("\(Int(d.minF.rounded()))°")
                            .font(RL.font(.subheadline)).foregroundStyle(RL.slate)
                        Text("\(d.rainPercent)%")
                            .font(RL.font(.caption, .semibold)).foregroundStyle(RL.pine)
                    }
                    .frame(width: 58)
                    .padding(.vertical, 8)
                    .background(RL.pineTint)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private static func weekday(_ date: Date, _ tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    // MARK: Sights

    private var sightsCard: some View {
        let visited = trip.sights.filter(\.visited).count
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(title: "Must-See Sights", symbol: "binoculars.fill")
                Spacer()
                Chip(text: "\(visited)/\(trip.sights.count)", tint: RL.blaze)
            }
            ForEach(trip.sights) { sight in
                VStack(alignment: .leading, spacing: 6) {
                    Divider().overlay(RL.border)
                    HStack(alignment: .top, spacing: 12) {
                        Button { store.toggleSight(sight.id) } label: {
                            Image(systemName: sight.visited ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(sight.visited ? RL.pine : RL.slate)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(sight.visited ? "Visited: \(sight.name)" : "Mark \(sight.name) visited")
                        VStack(alignment: .leading, spacing: 2) {
                            Label(sight.name, systemImage: sight.symbol)
                                .font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                                .strikethrough(sight.visited, color: RL.slate)
                            Text(sight.blurb).font(RL.font(.subheadline)).foregroundStyle(RL.slate)
                            if let place = trip.place(id: sight.placeID) {
                                DirectionsMenu(to: Endpoint(title: place.name, query: nil, coord: place.coord))
                            }
                        }
                    }
                }
            }
        }
        .rlCard()
    }
}

// MARK: - Destination setup for trips created without one

struct SetDestinationCard: View {
    @EnvironmentObject private var store: TripStore
    @EnvironmentObject private var location: LocationService
    @State private var name = ""
    @State private var latText = ""
    @State private var lonText = ""
    @State private var wantsLocation = false

    private var coord: Coord? {
        guard let lat = Double(latText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(lonText.trimmingCharacters(in: .whitespaces)),
              (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }
        return Coord(lat, lon)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Set Your Destination", symbol: "mappin.and.ellipse")
            Text("Add the trailhead or camp you're heading to for weather, daylight and map pins.")
                .font(RL.font(.subheadline)).foregroundStyle(RL.slate)
            TextField("Place name", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("Latitude", text: $latText).keyboardType(.numbersAndPunctuation)
                TextField("Longitude", text: $lonText).keyboardType(.numbersAndPunctuation)
            }
            .textFieldStyle(.roundedBorder)

            Button {
                wantsLocation = true
                location.start()
                fillFromLocation()
            } label: {
                Label("Use My Current Location", systemImage: "location.fill")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                guard let c = coord else { return }
                let title = name.trimmingCharacters(in: .whitespaces)
                store.setDestination(Place(id: "dest-\(UUID().uuidString)", name: title.isEmpty ? "Destination" : title,
                                           subtitle: "", kind: .landmark, coord: c))
            } label: {
                Label("Save Destination", systemImage: "checkmark")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(coord == nil)
            .opacity(coord == nil ? 0.5 : 1)
        }
        .rlCard()
        .onChange(of: location.location) { _, _ in fillFromLocation() }
    }

    /// Fills the coordinate fields once the first GPS fix arrives after the user asked for it.
    private func fillFromLocation() {
        guard wantsLocation, let loc = location.location else { return }
        latText = String(format: "%.5f", loc.coordinate.latitude)
        lonText = String(format: "%.5f", loc.coordinate.longitude)
        wantsLocation = false
    }
}
