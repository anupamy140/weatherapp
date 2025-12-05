import Foundation

/// Simple suggestion shown in the "Add City" search list.
struct CitySuggestion: Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let state: String?

    var displayName: String {
        if let state = state, !state.isEmpty {
            return "\(name), \(state), \(country)"
        } else {
            return "\(name), \(country)"
        }
    }
}

final class CitySearchService {
    struct GeocodingResponse: Decodable {
        let results: [Item]?
    }

    struct Item: Decodable {
        let name: String
        let country: String
        let admin1: String?
    }

    func searchCities(
        matching query: String,
        completion: @escaping (Result<[CitySuggestion], Error>) -> Void
    ) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(.success([]))
            return
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host   = "geocoding-api.open-meteo.com"
        components.path   = "/v1/search"
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "20"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            completion(.success([]))
            return
        }

        print("🌐 City search:", url.absoluteString)

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.success([]))
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(GeocodingResponse.self, from: data)
                let items = decoded.results ?? []
                let suggestions = items.map {
                    CitySuggestion(
                        name: $0.name,
                        country: $0.country,
                        state: $0.admin1
                    )
                }

                DispatchQueue.main.async {
                    completion(.success(suggestions))
                }
            } catch {
                print("🔴 CitySearch decode error:", error)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

        task.resume()
    }
}
