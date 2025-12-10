import SwiftUI

struct CityListView: View {
    @StateObject private var viewModel =
        CityListViewModel(store: CityStore.shared,
                          weatherAPI: WeatherAPI.shared)

    @Environment(\.dismiss) private var dismiss
    @State private var showAddCity = false

    // Location manager for "Use my location"
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.50, blue: 0.98),
                    Color(red: 0.20, green: 0.80, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                headerBar

                if viewModel.isLoading && viewModel.cities.isEmpty {
                    // Initial loading
                    VStack {
                        ProgressView("Loading cities…")
                            .tint(.white)
                        Text("Fetching your saved cities.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if viewModel.cities.isEmpty {
                    // Empty state
                    VStack(spacing: 8) {
                        Text("No cities yet")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Tap + or use your location to add your first city.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    // Cities list
                    List {
                        ForEach(viewModel.cities) { city in
                            NavigationLink {
                                WeatherDetailView(city: city)
                            } label: {
                                CityRowCard(city: city)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: viewModel.deleteCities)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadCities()
        }
        // 🔁 Pull-to-refresh: refresh weather for all cities AND save to Firestore
        .refreshable {
            await viewModel.refreshAllWeather()
        }
        // Add City sheet – AddCitySearchView does saving & dismissing itself
        .sheet(isPresented: $showAddCity, onDismiss: {
            viewModel.loadCities()
        }) {
            NavigationStack {
                AddCitySearchView()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        // When LocationManager finds a city name, add it
        .onChange(of: locationManager.currentCityName) { newCity in
            guard let city = newCity else { return }
            viewModel.addCity(named: city)
        }
        .onChange(of: locationManager.lastErrorMessage) { message in
            if let msg = message {
                viewModel.errorMessage = msg
            }
        }

    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            // Back button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.20)))
            }

            Spacer()

            Text("Cities")
                .font(.title2.bold())
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 8) {
                // 👉 Use my location button with loader
                Button {
                    locationManager.requestCurrentCity()
                } label: {
                    Group {
                        if locationManager.isRequestingLocation {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.blue)
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(10)
                    .background(Circle().fill(Color.white))
                }
                .disabled(locationManager.isRequestingLocation)

                // Add city manually
                Button {
                    showAddCity = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Circle().fill(Color.white))
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - City card row

private struct CityRowCard: View {
    let city: City

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(.black.opacity(0.8))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.headline)
                    .foregroundColor(.black)

                Text(updatedText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if let weather = city.lastWeather {
                let temp = Int(weather.main.temp.rounded())
                Text("\(temp)°C")
                    .font(.headline)
                    .foregroundColor(tempColor(for: temp))
            } else {
                Text("--°C")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.10, green: 0.54, blue: 0.97),
                                    Color(red: 0.27, green: 0.84, blue: 0.57)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                )
        )
        .padding(.vertical, 4)
    }

    private var iconName: String {
        if let main = city.lastWeather?.weather.first?.main.lowercased() {
            switch main {
            case "clear": return "sun.max.fill"
            case "clouds": return "cloud.fill"
            case "rain", "drizzle": return "cloud.rain.fill"
            case "snow": return "cloud.snow.fill"
            case "thunderstorm": return "cloud.bolt.rain.fill"
            default: return "cloud.fill"
            }
        }
        return "cloud.fill"
    }

    private var updatedText: String {
        guard let lastUpdated = city.lastUpdated else {
            return "Never updated"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let rel = formatter.localizedString(for: lastUpdated, relativeTo: Date())
        return "Updated \(rel)"
    }

    private func tempColor(for temp: Int) -> Color {
        switch temp {
        case ..<10:   return .blue
        case 10..<25: return .green
        default:      return .orange
        }
    }
}
