import SwiftUI

struct FuelView: View {
    @EnvironmentObject private var store: TripStore

    private var trip: Trip { store.trip }
    private var fuel: FuelPlan { store.trip.fuel }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    truckCard
                    slidersCard
                    resultsGrid
                    if !fuel.stops.isEmpty { stopsCard }
                    resetButton
                }
                .padding(16)
            }
            .rlScreen()
            .navigationTitle("Fuel & Cost")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { TripMenuButton() } }
        }
    }

    // MARK: Truck

    private var truckCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: trip.vehicle, symbol: "truck.pickup.side.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Chip(text: "\(Int(fuel.tankGallons)) gal tank", symbol: "fuelpump.fill")
                    Chip(text: "13 city / 19 hwy", symbol: "speedometer", tint: RL.blaze)
                    Chip(text: "~15.5–16 combined loaded", symbol: "tent.fill")
                }
            }
            Text("A truck-bed tent and a loaded bed add drag — expect 1–2 MPG less than the sticker numbers.")
                .font(RL.font(.footnote)).foregroundStyle(RL.slate)
        }
        .rlCard()
    }

    // MARK: Sliders

    private var slidersCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sliderRow(title: "Roundtrip + forest road miles",
                      value: "\(Int(fuel.miles)) mi",
                      hint: fuel.breakdownNote.isEmpty ? nil : fuel.breakdownNote) {
                Slider(value: $store.trip.fuel.miles, in: FuelPlan.milesRange, step: 5)
            }
            sliderRow(title: "Average MPG (loaded)",
                      value: String(format: "%.1f MPG", fuel.mpg),
                      hint: "Highway cruising at 65 mph beats 75 by a couple of MPG.") {
                Slider(value: $store.trip.fuel.mpg, in: FuelPlan.mpgRange, step: 0.5)
            }
            sliderRow(title: "Gas price per gallon",
                      value: Fmt.usd(fuel.price) + "/gal",
                      hint: "Mountain stations usually run higher than Florida or Macon.") {
                Slider(value: $store.trip.fuel.price, in: FuelPlan.priceRange, step: 0.05)
            }
            Stepper(value: $store.trip.fuel.travelers, in: 1...6) {
                Text("Split between \(fuel.travelers) \(fuel.travelers == 1 ? "traveler" : "travelers")")
                    .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.ink)
            }
        }
        .rlCard()
    }

    private func sliderRow<S: View>(title: String, value: String, hint: String?, @ViewBuilder slider: () -> S) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.slate)
                Spacer()
                Text(value).font(RL.font(.title3, .bold)).foregroundStyle(RL.pine)
            }
            slider().tint(RL.pine).accessibilityLabel(title).accessibilityValue(value)
            if let hint { Text(hint).font(RL.font(.caption)).foregroundStyle(RL.slate) }
        }
    }

    // MARK: Results

    private var resultsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                resultTile("Gallons Burned", String(format: "%.1f gal", fuel.gallons), "drop.fill", RL.pine)
                resultTile("Tank Fill-Ups", String(format: "%.1f tanks", fuel.tanks), "fuelpump.fill", RL.pine)
                resultTile("Total Fuel Cost", Fmt.usd(fuel.totalCost), "dollarsign.circle.fill", RL.blaze)
                resultTile("Per Person", Fmt.usd(fuel.perPerson), "person.2.fill", RL.blaze)
            }
            Text("Range on a full tank at \(String(format: "%.1f", fuel.mpg)) MPG: about \(Int(fuel.rangePerTank)) miles.")
                .font(RL.font(.footnote)).foregroundStyle(RL.slate)
        }
    }

    private func resultTile(_ title: String, _ value: String, _ symbol: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(RL.font(.caption, .bold)).foregroundStyle(tint)
            Text(value)
                .font(RL.font(.title2, .bold)).foregroundStyle(RL.ink)
                .minimumScaleFactor(0.7).lineLimit(1)
        }
        .rlCard(padding: 14)
        .accessibilityElement(children: .combine)
    }

    // MARK: Pit stops

    private var stopsCard: some View {
        let stops = fuel.stops.sorted { $0.mile < $1.mile }
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Planned Pit Stops", symbol: "fuelpump.fill")
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                VStack(alignment: .leading, spacing: 4) {
                    if index > 0 { Divider().overlay(RL.border) }
                    HStack(alignment: .top) {
                        ZStack {
                            Circle().fill(index == 0 || index == stops.count - 1 ? RL.pine : RL.blaze)
                            Text("\(index + 1)").font(RL.font(.caption, .bold)).foregroundStyle(.white)
                        }
                        .frame(width: 26, height: 26)
                        .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.name).font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                            Text(stop.detail).font(RL.font(.subheadline)).foregroundStyle(RL.slate)
                            Text("Mile ~\(stop.mile) of \(trip.oneWayMiles)")
                                .font(RL.font(.caption, .semibold)).foregroundStyle(RL.pine)
                            if index > 0 { legSummary(from: stops[index - 1], to: stop) }
                        }
                    }
                }
            }
            if trip.oneWayMiles > 0 {
                Divider().overlay(RL.border)
                let back = fuel.gallons(forMiles: Double(trip.oneWayMiles))
                Label(String(format: "The drive home needs about %.1f gal — top off at the last mountain stop before heading out.", back),
                      systemImage: "arrow.uturn.backward")
                    .font(RL.font(.footnote)).foregroundStyle(RL.slate)
            }
        }
        .rlCard()
    }

    @ViewBuilder
    private func legSummary(from a: PitStop, to b: PitStop) -> some View {
        let miles = Double(b.mile - a.mile)
        let gal = fuel.gallons(forMiles: miles)
        let remaining = fuel.tankGallons - gal
        let pct = Int(max(0, remaining / max(fuel.tankGallons, 1)) * 100)
        if remaining < 0 {
            Label("\(Int(miles)) mi needs \(String(format: "%.1f", gal)) gal — more than one tank. Add a stop.",
                  systemImage: "exclamationmark.triangle.fill")
                .font(RL.font(.caption, .bold)).foregroundStyle(RL.blaze)
        } else {
            Text("\(Int(miles)) mi · ~\(String(format: "%.1f", gal)) gal · arrive with ~\(pct)% of a tank")
                .font(RL.font(.caption)).foregroundStyle(RL.slate)
        }
    }

    private var resetButton: some View {
        Button {
            store.resetFuelDefaults()
        } label: {
            Label("Reset to Trip Defaults", systemImage: "arrow.counterclockwise")
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}
