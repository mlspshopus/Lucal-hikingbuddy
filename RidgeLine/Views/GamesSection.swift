import SwiftUI

/// Card games and other camp games, with what to bring and how to play.
struct GamesSection: View {
    @EnvironmentObject private var store: TripStore
    @State private var detail: GameItem?

    private var trip: Trip { store.trip }

    private var kitMissing: Int { Suggestions.gameKit.filter { !store.hasGear(named: $0.name) }.count }

    var body: some View {
        VStack(spacing: 16) {
            kitCard
            ForEach(trip.games) { game in gameCard(game) }
            if trip.games.isEmpty {
                Text("No games on this trip.").font(RL.font(.subheadline)).foregroundStyle(RL.slate).rlCard()
            }
        }
        .sheet(item: $detail) { game in
            GameDetailSheet(game: game).presentationDetents([.large])
        }
    }

    private var kitCard: some View {
        let packed = trip.games.filter(\.packed).count
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(title: "Game Night Kit", symbol: "suit.spade.fill")
                Spacer()
                Chip(text: "\(packed)/\(trip.games.count) ready", tint: packed == trip.games.count && packed > 0 ? RL.pine : RL.blaze)
            }
            Text("Two plastic decks, a cribbage board, dice, a score pad and dominoes cover every game below. Plastic cards survive dew and spilled coffee.")
                .font(RL.font(.footnote)).foregroundStyle(RL.slate)
            ForEach(Suggestions.gameKit) { item in
                HStack(spacing: 8) {
                    Image(systemName: store.hasGear(named: item.name) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(store.hasGear(named: item.name) ? RL.pine : RL.slate)
                    Text(item.name).font(RL.font(.subheadline)).foregroundStyle(RL.ink)
                }
                .accessibilityElement(children: .combine)
            }
            if kitMissing > 0 {
                Button { store.addGameKit() } label: {
                    Label("Add \(kitMissing) Missing Kit Item\(kitMissing == 1 ? "" : "s") to Packing List", systemImage: "plus.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: RL.blaze))
            } else {
                Label("The whole kit is on your packing list.", systemImage: "checkmark.seal.fill")
                    .font(RL.font(.subheadline, .bold)).foregroundStyle(RL.pine)
            }
        }
        .rlCard()
    }

    private func gameCard(_ game: GameItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(game.name).font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Chip(text: game.kind, symbol: game.kind.hasPrefix("Card") ? "suit.spade.fill" : "dice.fill")
                    Chip(text: "\(game.players) players", symbol: "person.2.fill", tint: RL.blaze)
                    Chip(text: "~\(game.minutes) min", symbol: "clock.fill")
                }
            }
            Text(game.overview).font(RL.font(.subheadline)).foregroundStyle(RL.slate)
            Label("Bring: \(game.bring)", systemImage: "bag.fill")
                .font(RL.font(.footnote, .semibold)).foregroundStyle(RL.pine)
            HStack(spacing: 10) {
                Button { detail = game } label: { Label("How to Play", systemImage: "book.fill") }
                    .buttonStyle(PrimaryButtonStyle())
                Button { store.toggleGame(game.id) } label: {
                    Label(game.packed ? "Packed" : "Pack It", systemImage: game.packed ? "checkmark.circle.fill" : "circle")
                }
                .buttonStyle(SecondaryButtonStyle(tint: game.packed ? RL.pine : RL.blaze))
            }
        }
        .rlCard()
    }
}

struct GameDetailSheet: View {
    let game: GameItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        Chip(text: game.kind, symbol: game.kind.hasPrefix("Card") ? "suit.spade.fill" : "dice.fill")
                        Chip(text: "\(game.players) players", symbol: "person.2.fill", tint: RL.blaze)
                        Chip(text: "~\(game.minutes) min", symbol: "clock.fill")
                    }
                    Text(game.overview).font(RL.font(.body)).foregroundStyle(RL.ink)
                    Label("Bring: \(game.bring)", systemImage: "bag.fill")
                        .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.pine)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "How to play", symbol: "list.number")
                        ForEach(Array(game.rules.enumerated()), id: \.offset) { index, rule in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(RL.font(.caption, .bold)).foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(RL.pine))
                                    .accessibilityHidden(true)
                                Text(rule).font(RL.font(.body)).foregroundStyle(RL.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .rlCard()

                    Label(game.tip, systemImage: "lightbulb.fill")
                        .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.umber)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RL.blazeTint)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("Rules vary from house to house — agree on any tweaks before the first hand.")
                        .font(RL.font(.footnote)).foregroundStyle(RL.slate)
                }
                .padding(16)
            }
            .rlScreen()
            .navigationTitle(game.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.bold) } }
        }
    }
}
