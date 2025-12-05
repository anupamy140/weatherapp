import Foundation

/// Simple model representing a city and its cached weather.
struct City: Codable, Identifiable {
    /// Use lowercase name as a stable id for SwiftUI.
    var id: String { name.lowercased() }

    let name: String
    var lastWeather: WeatherResponse?
    var lastUpdated: Date?
}
