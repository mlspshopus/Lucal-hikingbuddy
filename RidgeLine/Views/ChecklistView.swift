import SwiftUI

struct ChecklistView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case gear = "Gear"
        case food = "Food"
        case games = "Games"
        var id: String { rawValue }
    }

    @EnvironmentObject private var store: TripStore
    @State private var mode: Mode = .gear

    @State private var showGearSuggestions = false
    @State private var showFoodSuggestions = false
    @State private var isEditing = false
    @State private var confirmReset = false

    private var trip: Trip { store.trip }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Checklist", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch mode {
                    case .gear: gearContent
                    case .food: foodContent
                    case .games: GamesSection()
                    }
                }
                .padding(16)
            }
            .rlScreen()
            .navigationTitle("Checklists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if mode != .games {
                            Button {
                                isEditing.toggle()
                            } label: {
                                Label(isEditing ? "Done Removing" : "Remove Items…",
                                      systemImage: isEditing ? "checkmark" : "minus.circle")
                            }
                        }
                        Button(role: .destructive) { confirmReset = true } label: {
                            Label("Reset Progress…", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle").frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("List options")
                }
                ToolbarItem(placement: .topBarTrailing) { TripMenuButton() }
            }
            .onChange(of: mode) { _, _ in isEditing = false }
            .confirmationDialog("Reset this trip's progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Move All Gear Back to “At Home”", role: .destructive) { store.setStage(.atHome, forCategory: nil) }
                Button("Uncheck All Food", role: .destructive) {
                    store.update { t in for i in t.food.indices { t.food[i].bought = false } }
                }
                Button("Unpack All Games", role: .destructive) {
                    store.update { t in for i in t.games.indices { t.games[i].packed = false } }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showGearSuggestions) { SuggestionsSheet(kind: .gear) }
            .sheet(isPresented: $showFoodSuggestions) { SuggestionsSheet(kind: .food) }
        }
    }

    // MARK: Gear

    private func count(_ stage: GearStage) -> Int { trip.gear.filter { $0.stage == stage }.count }

    private var gearContent: some View {
        let total = max(trip.gear.count, 1)
        let packed = count(.packed)
        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionTitle(title: packed == trip.gear.count && !trip.gear.isEmpty ? "Ready to roll!" : "3-Stage Anti-Forget",
                                 symbol: packed == trip.gear.count && !trip.gear.isEmpty ? "checkmark.seal.fill" : "shield.checkered")
                    Spacer()
                    Text("\(packed)/\(trip.gear.count)")
                        .font(RL.font(.title3, .bold)).foregroundStyle(RL.pine)
                }
                ProgressView(value: Double(packed), total: Double(total)).tint(RL.pine)
                HStack(spacing: 8) {
                    stageCount(.atHome, tint: RL.slate)
                    stageCount(.driveway, tint: RL.blaze)
                    stageCount(.packed, tint: RL.pine)
                }
                Text("Tap an item's pill to move it: At Home → Driveway Staged → In \(trip.vehicleShort) / Pack. Only count it packed once you've seen it with your own eyes.")
                    .font(RL.font(.footnote)).foregroundStyle(RL.slate)
            }
            .rlCard()

            Button { showGearSuggestions = true } label: {
                Label("Browse Suggestions — Tap + to Add", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle(tint: RL.blaze))

            if isEditing {
                Label("Tap the red minus next to anything you don't need.", systemImage: "minus.circle.fill")
                    .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.blaze)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(trip.gearCategories, id: \.self) { category in
                gearCategoryCard(category)
            }
        }
    }

    private func stageCount(_ stage: GearStage, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count(stage))").font(RL.font(.title3, .bold)).foregroundStyle(tint)
            Text(stage == .atHome ? "At Home" : stage == .driveway ? "Staged" : "Packed")
                .font(RL.font(.caption, .semibold)).foregroundStyle(RL.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func gearCategoryCard(_ category: String) -> some View {
        let items = trip.gear.filter { $0.category == category }
        let packed = items.filter { $0.stage == .packed }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category).font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                Spacer(minLength: 8)
                Chip(text: "\(packed)/\(items.count)", tint: packed == items.count ? RL.pine : RL.blaze)
                Menu {
                    Button("Mark All Staged") { store.setStage(.driveway, forCategory: category) }
                    Button("Mark All Packed") { store.setStage(.packed, forCategory: category) }
                    Button("Reset to At Home") { store.setStage(.atHome, forCategory: category) }
                    Divider()
                    Button("Add Suggestions…") { showGearSuggestions = true }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3).foregroundStyle(RL.pine)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("\(category) options")
            }
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Divider().overlay(RL.border)
                    HStack(alignment: .top, spacing: 8) {
                        if isEditing {
                            Button { withAnimation { store.deleteGear(item.id) } } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 28)).foregroundStyle(RL.blaze)
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("Remove \(item.name)")
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(RL.font(.body, .semibold)).foregroundStyle(RL.ink)
                            Text(item.detail).font(RL.font(.footnote)).foregroundStyle(RL.slate)
                        }
                        Spacer(minLength: 0)
                    }
                    StagePill(stage: item.stage, vehicle: trip.vehicleShort) { store.cycleStage(item.id) }
                        .accessibilityLabel("\(item.name): \(item.stage.label(vehicle: trip.vehicleShort)). Double tap to advance.")
                }
            }
        }
        .rlCard()
    }

    // MARK: Food

    private var foodContent: some View {
        let bought = trip.food.filter(\.bought).count
        let total = trip.food.reduce(0) { $0 + $1.estCost }
        let remaining = trip.food.filter { !$0.bought }.reduce(0) { $0 + $1.estCost }
        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionTitle(title: "Food, Snacks & Buy List", symbol: "cart.fill")
                    Spacer()
                    Text("\(bought)/\(trip.food.count)").font(RL.font(.title3, .bold)).foregroundStyle(RL.pine)
                }
                ProgressView(value: Double(bought), total: Double(max(trip.food.count, 1))).tint(RL.pine)
                HStack(spacing: 8) {
                    costTile("Est. total", Fmt.usd(total), RL.slate)
                    costTile("Still to buy", Fmt.usd(remaining), RL.blaze)
                    costTile("Per person", Fmt.usd(total / Double(max(trip.fuel.travelers, 1))), RL.pine)
                }
                Text("Prices are rough estimates. Store all food and scented items in the cab overnight, never in the open bed.")
                    .font(RL.font(.footnote)).foregroundStyle(RL.slate)
            }
            .rlCard()

            quickAddCard

            Button { showFoodSuggestions = true } label: {
                Label("Browse All Food Ideas — Tap + to Add", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle(tint: RL.blaze))

            if isEditing {
                Label("Tap the red minus next to anything you don't need.", systemImage: "minus.circle.fill")
                    .font(RL.font(.subheadline, .semibold)).foregroundStyle(RL.blaze)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(foodCategories, id: \.self) { cat in
                let items = trip.food.filter { ($0.category ?? "Essentials") == cat }
                VStack(alignment: .leading, spacing: 0) {
                    Text(cat).font(RL.font(.headline, .bold)).foregroundStyle(RL.ink).padding(.bottom, 4)
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 { Divider().overlay(RL.border) }
                        foodRow(item)
                    }
                }
                .rlCard()
            }
        }
    }

    private var foodCategories: [String] {
        var seen = Set<String>()
        return trip.food.compactMap { item in
            let c = item.category ?? "Essentials"
            return seen.insert(c).inserted ? c : nil
        }
    }

    /// One-tap chips for the most useful things not on the list yet.
    private var quickAddCard: some View {
        let ideas = Suggestions.food.filter { !store.hasFood(named: $0.name) }.prefix(14)
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Quick Add", symbol: "bolt.fill")
            if ideas.isEmpty {
                Text("You've added everything on the quick list. Browse all ideas for more.")
                    .font(RL.font(.footnote)).foregroundStyle(RL.slate)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(ideas)) { idea in
                            Button {
                                withAnimation { store.addSuggestion(idea) }
                            } label: {
                                Label("\(idea.name) · \(Fmt.usd(idea.cost))", systemImage: "plus")
                                    .font(RL.font(.subheadline, .bold))
                                    .foregroundStyle(RL.pine)
                                    .padding(.horizontal, 12)
                                    .frame(minHeight: 44)
                                    .background(RL.pineTint)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(RL.pine.opacity(0.4), lineWidth: 1))
                            }
                        }
                    }
                }
            }
        }
        .rlCard()
    }

    private func costTile(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(RL.font(.headline, .bold)).foregroundStyle(tint).minimumScaleFactor(0.7).lineLimit(1)
            Text(title).font(RL.font(.caption, .semibold)).foregroundStyle(RL.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func foodRow(_ item: FoodItem) -> some View {
        HStack(spacing: 4) {
            if isEditing {
                Button { withAnimation { store.deleteFood(item.id) } } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28)).foregroundStyle(RL.blaze)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Remove \(item.name)")
            }
            foodToggleRow(item)
        }
    }

    private func foodToggleRow(_ item: FoodItem) -> some View {
        Button { store.toggleFood(item.id) } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.bought ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.bought ? RL.pine : RL.slate)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(RL.font(.body, .semibold)).foregroundStyle(RL.ink)
                        .strikethrough(item.bought, color: RL.slate)
                        .multilineTextAlignment(.leading)
                    Text(item.detail).font(RL.font(.footnote)).foregroundStyle(RL.slate)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Text(Fmt.usd(item.estCost)).font(RL.font(.subheadline, .bold)).foregroundStyle(RL.blaze)
            }
            .padding(.vertical, 10)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.name), \(Fmt.usd(item.estCost)), \(item.bought ? "bought" : "not bought yet")")
    }
}

/// The 3-stage physical-verification pill. Tapping advances 1 → 2 → 3 → back to 1.
struct StagePill: View {
    let stage: GearStage
    let vehicle: String
    let action: () -> Void

    private var fill: Color {
        switch stage {
        case .atHome: return Color(hex: 0xEFE8DA)
        case .driveway: return RL.blazeTint
        case .packed: return RL.pine
        }
    }

    private var textColor: Color {
        switch stage {
        case .atHome: return RL.slate
        case .driveway: return RL.umber
        case .packed: return .white
        }
    }

    private var stroke: Color {
        switch stage {
        case .atHome: return RL.border
        case .driveway: return RL.blaze
        case .packed: return RL.pine
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i <= stage.rawValue ? textColor : textColor.opacity(0.25))
                            .frame(width: 8, height: 8)
                    }
                }
                Text(stage.label(vehicle: vehicle))
                    .font(RL.font(.subheadline, .bold))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(fill)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(stroke, lineWidth: 1.5))
            .animation(.easeInOut(duration: 0.15), value: stage)
        }
        .buttonStyle(.plain)
    }
}
