import Foundation

struct City: Codable, Identifiable {
    var id: String { name.lowercased() }

    let name: String
    var lastWeather: WeatherResponse?
    var lastUpdated: Date?
    
    // 🚀 NEW: This field allows us to sort by "Oldest First"
    var dateAdded: Date?
}
