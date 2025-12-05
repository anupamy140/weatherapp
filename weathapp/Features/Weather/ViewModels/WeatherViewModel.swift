// WeatherViewModel.swift
import Foundation
import Combine
import SwiftUI

@MainActor
final class WeatherViewModel: ObservableObject {
    // Data shown on the detail screen
    @Published var weather: WeatherResponse?
    @Published var lastUpdated: Date?
    @Published var statusText: String?
    @Published var isLoading = false

    // The specific city this screen is for (includes cached data from Firestore)
    private(set) var city: City

    private let api: WeatherAPI
    private let cityStore: CityStore

    init(
        city: City,
        api: WeatherAPI = .shared,
        cityStore: CityStore = .shared
    ) {
        self.city = city
        self.api = api
        self.cityStore = cityStore

        // ✅ Use cached data that was loaded from Firestore
        self.weather = city.lastWeather
        self.lastUpdated = city.lastUpdated

        if weather == nil {
            statusText = "Pull to refresh to load weather."
        }
    }

    // MARK: - Simple helpers

    var cityName: String { city.name }
    var title: String { cityName }

    var isDaytime: Bool {
        guard let w = weather else { return true }
        let nowUTC = Int(Date().timeIntervalSince1970)
        let nowLocal = nowUTC + w.timezone
        let sunriseLocal = w.sys.sunrise + w.timezone
        let sunsetLocal = w.sys.sunset + w.timezone
        return nowLocal >= sunriseLocal && nowLocal < sunsetLocal
    }

    var backgroundGradient: [Color] {
        if isDaytime {
            return [
                Color(red: 0.13, green: 0.57, blue: 0.98),
                Color(red: 0.36, green: 0.79, blue: 1.00)
            ]
        } else {
            return [
                Color(red: 0.03, green: 0.07, blue: 0.24),
                Color(red: 0.02, green: 0.02, blue: 0.12)
            ]
        }
    }

    var conditionSymbolName: String {
        guard let main = weather?.weather.first?.main.lowercased() else {
            return "cloud.fill"
        }
        switch main {
        case "clear":        return isDaytime ? "sun.max.fill" : "moon.stars.fill"
        case "clouds":       return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "snow":         return "cloud.snow.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "mist", "fog", "haze", "smoke", "dust":
            return "cloud.fog.fill"
        default:             return "cloud.fill"
        }
    }

    func formattedUpdatedText() -> String {
        guard let date = lastUpdated else { return "Never updated" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let rel = formatter.localizedString(for: date, relativeTo: Date())
        return "Updated \(rel)"
    }

    var cityAndCountryText: String {
        guard let w = weather else { return cityName }
        return "\(w.name), \(w.sys.country)"
    }

    var descriptionText: String {
        weather?.weather.first?.description.capitalized ?? "—"
    }

    var feelsLikeText: String {
        guard let w = weather else { return "—" }
        return "\(Int(w.main.feelsLike.rounded()))°"
    }

    var tempMinText: String {
        guard let w = weather else { return "—" }
        return "\(Int(w.main.tempMin.rounded()))°"
    }

    var tempMaxText: String {
        guard let w = weather else { return "—" }
        return "\(Int(w.main.tempMax.rounded()))°"
    }

    var humidityText: String {
        guard let h = weather?.main.humidity else { return "—" }
        return "\(h)%"
    }

    var windText: String {
        guard let s = weather?.wind.speed else { return "—" }
        return String(format: "%.1f m/s", s)
    }

    var sunriseText: String {
        guard let w = weather else { return "—" }
        return formatTime(timestamp: w.sys.sunrise, tzOffset: w.timezone)
    }

    var sunsetText: String {
        guard let w = weather else { return "—" }
        return formatTime(timestamp: w.sys.sunset, tzOffset: w.timezone)
    }

    private func formatTime(timestamp: Int, tzOffset: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp + tzOffset))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = TimeZone(secondsFromGMT: tzOffset)
        return formatter.string(from: date)
    }

    // MARK: - REFRESH (this now ALSO saves to Firestore)

    func refreshAsync() async {
        isLoading = true
        statusText = "Loading…"

        do {
            // 1️⃣ Get fresh data from API
            let newWeather = try await api.fetchWeatherAsync(for: cityName)
            let now = Date()

            // 2️⃣ Update detail screen immediately
            self.weather = newWeather
            self.lastUpdated = now
            self.statusText = nil

            // 3️⃣ Update local city copy
            self.city.lastWeather = newWeather
            self.city.lastUpdated = now

            // 4️⃣ Save to Firestore using your CityStore implementation
            cityStore.updateWeather(for: city.name, with: newWeather) { error in
                if let error = error {
                    print("❌ Failed to update city weather in Firestore:", error)
                } else {
                    print("✅ Updated weather in Firestore for city:", self.city.name)
                }
            }

        } catch {
            print("❌ Weather refresh error:", error)
            if self.weather == nil {
                self.statusText = "Could not load weather."
            } else {
                self.statusText = "Last update failed."
            }
        }

        isLoading = false
    }
}
