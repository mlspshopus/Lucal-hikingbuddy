import SwiftUI

struct TripManagerView: View {
    private enum Template: String, CaseIterable, Identifiable {
        case copyBlood = "Copy of the Blood Mountain trip"
        case starter = "Blank trip with starter checklists"
        var id: String { rawValue }
    }

    @EnvironmentObject private var store: TripStore
    @Environment(\.dismiss) private var dismiss

    @State private var newName = ""
    @State private var template: Template = .starter
    @State private var renaming: Trip?
    @State private var renameText = ""
    @State private var deleting: Trip?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionTitle(title: "Your Trips", symbol: "suitcase.rolling.fill").padding(.bottom, 8)
                        ForEach(Array(store.trips.enumerated()), id: \.element.id) { index, trip in
                            if index > 0 { Divider().overlay(RL.border) }
                            tripRow(trip)
                        }
                    }
                    .rlCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Plan a New Trip", symbol: "plus.circle.fill")
                        TextField("Trip name (e.g. Smokies in April)", text: $newName)
                            .textFieldStyle(.roundedBorder)
                        Picker("Start from", selection: $template) {
                            ForEach(Template.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(RL.pine)
                        Text("Either option brings the full gear and food checklists with it — no typing needed.")
                            .font(RL.font(.footnote)).foregroundStyle(RL.slate)
                        Button { create() } label: { Label("Create Trip", systemImage: "checkmark") }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(trimmedName.isEmpty)
                            .opacity(trimmedName.isEmpty ? 0.5 : 1)
                    }
                    .rlCard()
                }
                .padding(16)
            }
            .rlScreen()
            .navigationTitle("Manage Trips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.bold) } }
            .alert("Rename Trip", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
                TextField("Trip name", text: $renameText)
                Button("Save") {
                    if let t = renaming { store.rename(id: t.id, to: renameText) }
                    renaming = nil
                }
                Button("Cancel", role: .cancel) { renaming = nil }
            }
            .confirmationDialog("Delete this trip?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                                titleVisibility: .visible) {
                Button("Delete \(deleting?.name ?? "Trip")", role: .destructive) {
                    if let t = deleting { store.deleteTrip(id: t.id) }
                    deleting = nil
                }
                Button("Cancel", role: .cancel) { deleting = nil }
            } message: {
                Text("Its checklists, pins and routes will be removed from this device.")
            }
        }
    }

    private var trimmedName: String { newName.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func tripRow(_ trip: Trip) -> some View {
        HStack(spacing: 12) {
            Button {
                store.activeTripID = trip.id
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: trip.id == store.activeTripID ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(trip.id == store.activeTripID ? RL.pine : RL.slate)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.name).font(RL.font(.headline, .bold)).foregroundStyle(RL.ink)
                        Text(trip.subtitle).font(RL.font(.footnote)).foregroundStyle(RL.slate)
                    }
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button { renameText = trip.name; renaming = trip } label: { Label("Rename", systemImage: "pencil") }
                if store.trips.count > 1 {
                    Button(role: .destructive) { deleting = trip } label: { Label("Delete", systemImage: "trash") }
                }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3).foregroundStyle(RL.pine).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Options for \(trip.name)")
        }
    }

    private func create() {
        let name = trimmedName
        guard !name.isEmpty else { return }
        switch template {
        case .copyBlood:
            let source = store.trips.first { $0.places.contains { $0.id == "byron-reece-th" } } ?? Trip.bloodMountain()
            store.addTrip(source.duplicated(as: name))
        case .starter:
            store.addTrip(Trip.starter(name: name))
        }
        dismiss()
    }
}
