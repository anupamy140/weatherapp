// CityListViewModel.swift
import Foundation
import Combine
import SwiftUI   // needed for remove(atOffsets:)

@MainActor
final class CityListViewModel: ObservableObject {
    @Published var cities: [City] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let store: CityStore
    private let weatherAPI: WeatherAPI

    // NOTE: no default arguments here (Swift 6 / @MainActor safe)
    init(store: CityStore, weatherAPI: WeatherAPI) {
        self.store = store
        self.weatherAPI = weatherAPI
    }

    /// Load all cities from Firestore for the current user.
    func loadCities() {
        isLoading = true
        errorMessage = nil

        store.fetchCities { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let cities):
                    self.cities = cities.sorted {
                        $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Delete selected cities from list and Firestore.
    func deleteCities(at offsets: IndexSet) {
        let idsToDelete: [String] = offsets.compactMap { index in
            guard index < cities.count else { return nil }
            return cities[index].id
        }

        cities.remove(atOffsets: offsets)

        for id in idsToDelete {
            store.deleteCity(id: id) { error in
                if let error = error {
                    print("❌ Failed to delete city \(id):", error)
                } else {
                    print("✅ Deleted city \(id)")
                }
            }
        }
    }

    /// Refresh weather for *all* cities using the API, and save back to Firestore.
    func refreshAllWeather() async {
        guard !cities.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        // Work on a local copy to avoid index issues while mutating.
        let currentCities = cities
        var updatedCities: [City] = []

        for city in currentCities {
            do {
                // 1️⃣ Fetch latest weather for this city
                let weather = try await weatherAPI.fetchWeatherAsync(for: city.name)

                // 2️⃣ Create updated city
                var updated = city
                updated.lastWeather = weather
                updated.lastUpdated = Date()
                updatedCities.append(updated)

                // 3️⃣ Save to Firestore (no need to wait)
                store.saveCity(updated) { error in
                    if let error = error {
                        print("❌ Failed to save updated city \(updated.name):", error)
                    } else {
                        print("✅ Updated city \(updated.name) with fresh weather")
                    }
                }
            } catch {
                print("❌ Failed to refresh weather for \(city.name):", error)
                // Keep old city if update fails
                updatedCities.append(city)
            }
        }

        // 4️⃣ Update UI with refreshed list
        cities = updatedCities.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        isLoading = false
    }
}
