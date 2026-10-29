import Foundation
import SwiftUI

/// Source of truth for every trip. Persists to a single JSON file in Application Support.
@MainActor
final class TripStore: ObservableObject {
    @Published private(set) var trips: [Trip] = []
    @Published var activeTripID = UUID() { didSet { scheduleSave() } }

    private let fileURL: URL
    private var saveTask: Task<Void, Never>?

    private struct Library: Codable {
        var trips: [Trip]
        var activeTripID: UUID
    }

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultURL()
        if let lib = Self.load(from: self.fileURL), !lib.trips.isEmpty {
            trips = lib.trips
            activeTripID = lib.trips.contains { $0.id == lib.activeTripID } ? lib.activeTripID : lib.trips[0].id
        } else {
            let first = Trip.bloodMountain()
            trips = [first]
            activeTripID = first.id
        }
    }

    // MARK: Active trip

    /// The currently selected trip. Writing back persists automatically.
    var trip: Trip {
        get { trips.first { $0.id == activeTripID } ?? trips[0] }
        set {
            guard let i = trips.firstIndex(where: { $0.id == newValue.id }) else { return }
            trips[i] = newValue
            scheduleSave()
        }
    }

    func update(_ change: (inout Trip) -> Void) {
        var t = trip
        change(&t)
        trip = t
    }

    // MARK: Trip management

    func addTrip(_ t: Trip, activate: Bool = true) {
        trips.append(t)
        if activate { activeTripID = t.id }
        scheduleSave()
    }

    func deleteTrip(id: UUID) {
        guard trips.count > 1 else { return }
        trips.removeAll { $0.id == id }
        if activeTripID == id { activeTripID = trips[0].id }
        scheduleSave()
    }

    func rename(id: UUID, to name: String) {
        guard let i = trips.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        trips[i].name = trimmed
        scheduleSave()
    }

    // MARK: Gear

    func cycleStage(_ id: UUID) {
        update { t in
            if let i = t.gear.firstIndex(where: { $0.id == id }) { t.gear[i].stage = t.gear[i].stage.next }
        }
    }

    func setStage(_ stage: GearStage, forCategory category: String?) {
        update { t in
            for i in t.gear.indices where category == nil || t.gear[i].category == category {
                t.gear[i].stage = stage
            }
        }
    }

    func addGear(name: String, category: String, detail: String = "Custom item") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update { t in
            guard !t.gear.contains(where: { Self.same($0.name, trimmed) }) else { return }
            t.gear.append(GearItem(name: trimmed, detail: detail, category: category))
        }
    }

    func addSuggestion(_ s: GearSuggestion) { addGear(name: s.name, category: s.category, detail: s.detail) }

    func addGameKit() { Suggestions.gameKit.forEach { addSuggestion($0) } }

    /// Removes every item with this name (used by the suggestion list's tap-again-to-remove).
    func removeGear(named name: String) { update { t in t.gear.removeAll { Self.same($0.name, name) } } }

    func hasGear(named name: String) -> Bool { trip.gear.contains { Self.same($0.name, name) } }

    func deleteGear(_ id: UUID) { update { $0.gear.removeAll { $0.id == id } } }

    nonisolated static func same(_ a: String, _ b: String) -> Bool {
        a.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(b.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }

    // MARK: Food

    func toggleFood(_ id: UUID) {
        update { t in
            if let i = t.food.firstIndex(where: { $0.id == id }) { t.food[i].bought.toggle() }
        }
    }

    func addFood(name: String, cost: Double, detail: String = "Custom item", category: String? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update { t in
            guard !t.food.contains(where: { Self.same($0.name, trimmed) }) else { return }
            t.food.append(FoodItem(name: trimmed, detail: detail, estCost: max(0, cost), category: category ?? "Added by you"))
        }
    }

    func addSuggestion(_ s: FoodSuggestion) { addFood(name: s.name, cost: s.cost, detail: s.detail, category: s.category) }

    func removeFood(named name: String) { update { t in t.food.removeAll { Self.same($0.name, name) } } }

    func hasFood(named name: String) -> Bool { trip.food.contains { Self.same($0.name, name) } }

    func deleteFood(_ id: UUID) { update { $0.food.removeAll { $0.id == id } } }

    // MARK: Games

    func toggleGame(_ id: String) {
        update { t in
            if let i = t.games.firstIndex(where: { $0.id == id }) { t.games[i].packed.toggle() }
        }
    }

    // MARK: Sights, routes, places

    func toggleSight(_ id: String) {
        update { t in
            if let i = t.sights.firstIndex(where: { $0.id == id }) { t.sights[i].visited.toggle() }
        }
    }

    func setActiveRoute(_ id: String) { update { $0.activeRouteID = id } }

    func addRoute(_ r: HikeRoute) {
        update { t in
            t.routes.append(r)
            t.activeRouteID = r.id
        }
    }

    func deleteRoute(_ id: String) {
        update { t in
            t.routes.removeAll { $0.id == id }
            if t.activeRouteID == id { t.activeRouteID = t.routes.first?.id }
        }
    }

    func addPlace(_ p: Place) { update { $0.places.append(p) } }

    func setDestination(_ p: Place) {
        update { t in
            t.destination = p
            if !t.places.contains(where: { $0.id == p.id }) { t.places.append(p) }
        }
    }

    // MARK: Fuel

    func resetFuelDefaults() {
        update { t in
            t.fuel.miles = 910
            t.fuel.mpg = 16.0
            t.fuel.price = 3.15
        }
    }

    // MARK: Persistence

    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        saveTask?.cancel()
        let lib = Library(trips: trips, activeTripID: activeTripID)
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(lib)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Non-fatal: the in-memory state is still correct and the next change retries the write.
            print("RidgeLine: save failed — \(error)")
        }
    }

    private static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("RidgeLine", isDirectory: true).appendingPathComponent("trips.json")
    }

    private static func load(from url: URL) -> Library? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(Library.self, from: data)
        } catch {
            // Keep the unreadable file for recovery rather than silently overwriting it.
            let backup = url.deletingLastPathComponent().appendingPathComponent("trips.unreadable.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
            return nil
        }
    }
}
