import Foundation

enum WeatherError: Error {
    case invalidURL
    case noData
    case decodingFailed
}

final class WeatherAPI {
    static let shared = WeatherAPI()

    // Put your OpenWeather API key here
    private let apiKey = "c99e87039272851c36ad46c6c405c35b"

    private init() {}

    // MARK: - Completion-based API (still available if you need it)

    func fetchWeather(
        for city: String,
        completion: @escaping (Result<WeatherResponse, Error>) -> Void
    ) {
        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")
        components?.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]

        guard let url = components?.url else {
            completion(.failure(WeatherError.invalidURL))
            return
        }

        print("➡️ Requesting:", url.absoluteString)

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(WeatherError.noData))
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                let weather = try decoder.decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(weather))
                }
            } catch {
                print("❌ WeatherAPI decode error:", error)
                DispatchQueue.main.async {
                    completion(.failure(WeatherError.decodingFailed))
                }
            }
        }.resume()
    }

    // MARK: - Async / await version

    func fetchWeatherAsync(for city: String) async throws -> WeatherResponse {
        try await withCheckedThrowingContinuation { continuation in
            self.fetchWeather(for: city) { result in
                switch result {
                case .success(let weather):
                    continuation.resume(returning: weather)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
