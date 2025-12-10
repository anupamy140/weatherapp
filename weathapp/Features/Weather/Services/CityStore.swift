import Foundation
import FirebaseFirestore
import FirebaseAuth

enum CityStoreError: Error {
    case noUser
}

/// Repository that stores each user's cities in Firestore:
/// profiles/{uid}/cities/{cityId}
final class CityStore {
    static let shared = CityStore()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Helpers

    private func citiesCollection() throws -> CollectionReference {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw CityStoreError.noUser
        }
        return db
            .collection("profiles")
            .document(uid)
            .collection("cities")
    }

    private func encode(_ city: City) throws -> [String: Any] {
        let data = try JSONEncoder().encode(city)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    private func decodeCity(from dict: [String: Any]) throws -> City {
        let data = try JSONSerialization.data(withJSONObject: dict)
        let city = try JSONDecoder().decode(City.self, from: data)
        return city
    }

    // MARK: - Public API

    func fetchCities(completion: @escaping (Result<[City], Error>) -> Void) {
        do {
            let col = try citiesCollection()
            col.getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let docs = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                var results: [City] = []

                for doc in docs {
                    do {
                        let city = try self.decodeCity(from: doc.data())
                        results.append(city)
                    } catch {
                        print("❌ Failed to decode City from doc \(doc.documentID):", error)
                    }
                }

                completion(.success(results))
            }
        } catch {
            completion(.failure(error))
        }
    }

    /// Add a new city (without weather yet).
    func addCity(named name: String, completion: ((Error?) -> Void)? = nil) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            completion?(nil)
            return
        }

        // ✅ UPDATED: Initialize with dateAdded
        let city = City(
            name: cleanName,
            lastWeather: nil,
            lastUpdated: nil,
            dateAdded: Date()
        )
        saveCity(city, completion: completion)
    }

    /// Save (insert or overwrite) a City document.
    func saveCity(_ city: City, completion: ((Error?) -> Void)? = nil) {
        do {
            let col = try citiesCollection()
            let dict = try encode(city)
            col.document(city.id).setData(dict) { error in
                if let error = error {
                    print("❌ Failed to save city \(city.name):", error)
                }
                completion?(error)
            }
        } catch {
            print("❌ Encoding error saving city:", error)
            completion?(error)
        }
    }

    /// Update just the weather for a given city name.
    func updateWeather(
        for name: String,
        with weather: WeatherResponse,
        completion: ((Error?) -> Void)? = nil
    ) {
        do {
            let col = try citiesCollection()
            let docId = name.lowercased()

            col.document(docId).getDocument { snapshot, error in
                if let error = error {
                    print("❌ Failed to fetch city before update:", error)
                    completion?(error)
                    return
                }

                // ✅ UPDATED: Include dateAdded for the fallback "new city" case
                var city = City(
                    name: name,
                    lastWeather: weather,
                    lastUpdated: Date(),
                    dateAdded: Date()
                )

                if let data = snapshot?.data() {
                    // Try to merge with existing city
                    do {
                        var existing = try self.decodeCity(from: data)
                        existing.lastWeather = weather
                        existing.lastUpdated = Date()
                        // existing.dateAdded is automatically preserved
                        city = existing
                    } catch {
                        print("⚠️ Failed to decode existing city, overwriting:", error)
                    }
                }

                self.saveCity(city, completion: completion)
            }
        } catch {
            completion?(error)
        }
    }

    func deleteCity(id: String, completion: ((Error?) -> Void)? = nil) {
        do {
            let col = try citiesCollection()
            col.document(id).delete { error in
                if let error = error {
                    print("❌ Failed to delete city \(id):", error)
                }
                completion?(error)
            }
        } catch {
            completion?(error)
        }
    }
}
