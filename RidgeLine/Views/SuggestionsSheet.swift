import SwiftUI

/// Tap-to-add idea lists. A plus adds the item to the packing / buy list; tapping the check removes it again.
struct SuggestionsSheet: View {
    enum Kind { case gear, food }

    let kind: Kind

    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var category: String?
    @State private var customName = ""
    @State private var customCost = ""

    private var categories: [String] { kind == .gear ? Suggestions.gearCategories : Suggestions.foodCategories }

    private func matches(_ name: String, _ detail: String) -> Bool {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty || name.localizedCaseInsensitiveContains(q) || detail.localizedCaseInsensitiveContains(q)
    }

    private var gearItems: [GearSuggestion] {
        Suggestions.gear.filter { (category == nil || $0.category == category) && matches($0.name, $0.detail) }
    }

    private var foodItems: [FoodSuggestion] {
        Suggestions.food.filter { (category == nil || $0.category == category) && matches($0.name, $0.detail) }
    }

    private var addedCount: Int {
        switch kind {
        case .gear: return Suggestions.gear.filter { store.hasGear(named: $0.name) }.count
        case .food: return Suggestions.food.filter { store.hasFood(named: $0.name) }.count
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    categoryChips
                    ForEach(categories, id: \.self) { cat in
                        if category == nil || category == cat { section(cat) }
                    }
                    customCard
                }
                .padding(16)
            }
            .rlScreen()
            .navigationTitle(kind == .gear ? "Suggested Gear" : "Suggested Food")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: kind == .gear ? "Search gear ideas" : "Search food ideas")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("\(addedCount) added").font(RL.font(.subheadline, .bold)).foregroundStyle(RL.pine)
                }
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.bold) }
            }
        }
    }

    // MARK: Pieces

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", selected: category == nil) { category = nil }
                ForEach(categories, id: \.self) { c in
                    chip(c, selected: category == c) { category = (category == c) ? nil : c }
                }
            }
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(RL.font(.subheadline, .bold))
                .foregroundStyle(selected ? .white : RL.pine)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(selected ? RL.pine : RL.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(RL.pine.opacity(0.5), lineWidth: 1.5))
        }
    }

    @ViewBuilder
    private func section(_ cat: String) -> some View {
        switch kind {
        case .gear:
            let items = gearItems.filter { $0.category == cat }
            if !items.isEmpty {
                sectionCard(title: cat, count: items.count,
                            addAll: { items.forEach { store.addSuggestion($0) } },
                            allAdded: items.allSatisfy { store.hasGear(named: $0.name) }) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, s in
                        if index > 0 { Divider().overlay(RL.border) }
                        row(name: s.name, detail: s.detail, cost: nil, added: store.hasGear(named: s.name)) {
                            if store.hasGear(named: s.name) { store.removeGear(named: s.name) } else { store.addSuggestion(s) }
                        }
                    }
                }
            }
        case .food:
            let items = foodItems.filter { $0.category == cat }
            if !items.isEmpty {
                sectionCard(title: cat, count: items.count,
                            addAll: { items.forEach { store.addSuggestion($0) } },
                            allAdded: items.allSatisfy { store.hasFood(named: $0.name) }) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, s in
                        if index > 0 { Divider().overlay(RL.border) }
                        row(name: s.name, detail: s.detail, cost: s.cost, added: store.hasFood(named: s.name)) {
                            if store.hasFood(named: s.name) { store.removeFood(named: s.name) } else { store.addSuggestion(s) }
                        }
                    }
                }
            }
        }
    }

    private func sectionCard<Content: View>(title: String, count: Int, addAll: @escaping () -> Void, allAdded: Bool,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                Spacer()
                if !allAdded {
                    Button("Add All \(count)", action: addAll)
                        .font(RL.font(.subheadline, .bold)).foregroundStyle(RL.blaze)
                        .frame(minHeight: 44)
                } else {
                    Label("All added", systemImage: "checkmark")
                        .font(RL.font(.subheadline, .bold)).foregroundStyle(RL.pine)
                }
            }
            content()
        }
        .rlCard()
    }

    private func row(name: String, detail: String, cost: Double?, added: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(RL.font(.body, .semibold)).foregroundStyle(RL.ink)
                        .multilineTextAlignment(.leading)
                    Text(detail).font(RL.font(.footnote)).foregroundStyle(RL.slate)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                if let cost {
                    Text(Fmt.usd(cost)).font(RL.font(.subheadline, .bold)).foregroundStyle(RL.blaze)
                }
                Image(systemName: added ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(added ? RL.pine : RL.blaze)
                    .frame(width: 44, height: 44)
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(added ? "\(name), added. Double tap to remove." : "Add \(name)")
    }

    private var customCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Not listed? Add your own", symbol: "square.and.pencil")
            TextField(kind == .gear ? "Item name" : "Food name", text: $customName)
                .textFieldStyle(.roundedBorder)
            if kind == .food {
                TextField("Estimated cost (optional)", text: $customCost)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
            Button {
                switch kind {
                case .gear: store.addGear(name: customName, category: category ?? "My Items")
                case .food: store.addFood(name: customName, cost: Double(customCost) ?? 0)
                }
                customName = ""
                customCost = ""
            } label: { Label("Add to List", systemImage: "plus") }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(customName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .rlCard()
    }
}
