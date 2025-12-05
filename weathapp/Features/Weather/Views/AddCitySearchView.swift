import SwiftUI

struct AddCitySearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var suggestions: [CitySuggestion] = []
    @State private var isLoading = false
    @State private var stateText: String? = "Start typing a city name…"

    @State private var isSaving = false
    @State private var saveErrorMessage: String?

    private let searchService = CitySearchService()
    private let weatherAPI = WeatherAPI.shared
    private let cityStore = CityStore.shared
    @State private var searchTask: DispatchWorkItem?

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.57, blue: 0.98),
                    Color(red: 0.36, green: 0.79, blue: 1.00)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Main content
            VStack(spacing: 8) {
                TextField("Search city", text: $query)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    )
                    .padding(.horizontal)
                    .onChange(of: query) { _, newValue in
                        handleQueryChange(newValue)
                    }

                if let state = stateText {
                    Text(state)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 4)
                }

                List {
                    ForEach(suggestions) { suggestion in
                        Button {
                            addSelectedCity(suggestion)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(suggestion.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            // Saving overlay
            if isSaving {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()

                VStack(spacing: 8) {
                    ProgressView("Adding city…")
                        .tint(.white)
                    Text("Fetching latest weather and saving.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.6))
                )
            }
        }
        .navigationTitle("Add City")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { _ in saveErrorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    // MARK: - Search handling

    private func handleQueryChange(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask?.cancel()

        guard trimmed.count >= 2 else {
            suggestions = []
            isLoading = false
            stateText = trimmed.isEmpty ? "Start typing a city name…" : "Type at least 2 letters"
            return
        }

        isLoading = true
        stateText = "Searching…"

        let work = DispatchWorkItem { [weak searchService] in
            searchService?.searchCities(matching: trimmed) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let cities):
                        self.suggestions = cities
                        self.stateText = cities.isEmpty ? "No cities found" : nil
                    case .failure:
                        self.suggestions = []
                        self.stateText = "Something went wrong. Please try again."
                    }
                }
            }
        }

        searchTask = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    // MARK: - Add city (with weather + Firestore)

    private func addSelectedCity(_ suggestion: CitySuggestion) {
        let cityName = suggestion.name
        isSaving = true
        saveErrorMessage = nil

        Task {
            do {
                // 1️⃣ Fetch latest weather for that city
                let weather = try await weatherAPI.fetchWeatherAsync(for: cityName)

                // 2️⃣ Build City with weather + lastUpdated
                let newCity = City(
                    name: cityName,
                    lastWeather: weather,
                    lastUpdated: Date()
                )

                // 3️⃣ Save to Firestore via CityStore
                cityStore.saveCity(newCity) { error in
                    DispatchQueue.main.async {
                        self.isSaving = false
                        if let error = error {
                            print("❌ Failed to save city:", error)
                            self.saveErrorMessage = "Failed to save city. Please try again."
                        } else {
                            print("✅ Saved city \(cityName) with weather")
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    print("❌ Failed to fetch weather for \(cityName):", error)
                    self.saveErrorMessage = "Could not fetch weather for \(cityName). Please try again."
                }
            }
        }
    }
}
