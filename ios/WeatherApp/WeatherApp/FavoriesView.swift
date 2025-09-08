//
//  FavoriesView.swift
//  WeatherApp
//
//  Created by Rahul Rajesh on 9/8/25.
//
import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favorites: FavoritesStore
    @EnvironmentObject var session: AppSession          // ← add this

    @State private var showAdd = false
    @State private var name = ""
    @State private var latText = ""
    @State private var lonText = ""
    @State private var inputError: String?

    var body: some View {
        NavigationStack {
            List {
                if favorites.places.isEmpty {
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "star",
                        description: Text("Tap the + button to add a city with latitude and longitude.")
                    )
                } else {
                    ForEach(favorites.places) { place in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name).font(.headline)
                                Text(String(format: "%.4f, %.4f", place.latitude, place.longitude))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if session.selectedPlace?.id == place.id {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { session.selectedPlace = place }   // ← select it
                    }
                    .onDelete { indexSet in
                        indexSet
                            .map { favorites.places[$0] }
                            .forEach { favorites.remove($0) }
                        // If we deleted the selected one, fall back to current location
                        if let sel = session.selectedPlace,
                           favorites.places.contains(where: { $0.id == sel.id }) == false {
                            session.selectedPlace = nil
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add favorite")
                }
            }
            .sheet(isPresented: $showAdd) {
                // (Your add sheet unchanged)
                NavigationStack {
                    Form {
                        Section("Place") {
                            TextField("Name (e.g., New York City)", text: $name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                        }
                        Section("Coordinates") {
                            TextField("Latitude (e.g., 40.7128)", text: $latText)
                                .keyboardType(.numbersAndPunctuation)
                            TextField("Longitude (e.g., -74.0060)", text: $lonText)
                                .keyboardType(.numbersAndPunctuation)
                        }
                        if let msg = inputError {
                            Text(msg).font(.footnote).foregroundStyle(.red)
                        }
                    }
                    .navigationTitle("Add Favorite")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismissAdd() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { saveFavorite() }.bold()
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }

    // saveFavorite() + dismissAdd() remain exactly as you posted
    private func saveFavorite() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { inputError = "Please enter a name."; return }
        guard let lat = Double(latText.replacingOccurrences(of: " ", with: "")),
              let lon = Double(lonText.replacingOccurrences(of: " ", with: "")) else {
            inputError = "Latitude/Longitude must be numbers (e.g., 40.7128 and -74.0060)."
            return
        }
        guard (-90.0...90.0).contains(lat), (-180.0...180.0).contains(lon) else {
            inputError = "Coordinates out of range. Lat ∈ [-90, 90], Lon ∈ [-180, 180]."
            return
        }
        let place = Place(id: UUID(), name: trimmedName, latitude: lat, longitude: lon)
        favorites.add(place)
        dismissAdd()
    }

    private func dismissAdd() {
        showAdd = false
        name = ""; latText = ""; lonText = ""; inputError = nil
    }
}
