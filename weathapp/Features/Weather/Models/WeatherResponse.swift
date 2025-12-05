import Foundation

/// Matches the JSON from OpenWeather's current weather API.
struct WeatherResponse: Codable {
    let name: String
    let sys: Sys
    let main: Main
    let weather: [WeatherInfo]
    let wind: Wind
    let visibility: Int?
    let timezone: Int

    struct Sys: Codable {
        let country: String
        let sunrise: Int        // unix time (seconds)
        let sunset: Int         // unix time (seconds)
    }

    struct Main: Codable {
        let temp: Double
        let feelsLike: Double
        let tempMin: Double
        let tempMax: Double
        let humidity: Int
        let pressure: Int

        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case tempMin   = "temp_min"
            case tempMax   = "temp_max"
            case humidity
            case pressure
        }
    }

    struct WeatherInfo: Codable {
        let main: String
        let description: String
        let icon: String
    }

    struct Wind: Codable {
        let speed: Double
    }
}
