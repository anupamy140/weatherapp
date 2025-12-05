// ProfileService.swift
import Foundation
import FirebaseFirestore

final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Helpers

    private func encode(_ profile: UserProfile) throws -> [String: Any] {
        let data = try JSONEncoder().encode(profile)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
            return [:]
        }
        return dict
    }

    private func decode(_ dict: [String: Any]) throws -> UserProfile {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }

    // MARK: - Create / update

    /// Creates or updates the profile document at `profiles/{uid}`.
    func createProfile(uid: String,
                       fullName: String,
                       city: String,
                       email: String,
                       completion: ((Error?) -> Void)? = nil) {

        let profile = UserProfile(uid: uid,
                                  fullName: fullName,
                                  city: city,
                                  email: email)

        do {
            let data = try encode(profile)

            db.collection("profiles")
                .document(uid)
                .setData(data, merge: true) { error in
                    if let error = error {
                        print("❌ Failed to create/update profile:", error)
                    } else {
                        print("✅ Profile saved for uid:", uid)
                    }
                    completion?(error)
                }
        } catch {
            print("❌ Encoding UserProfile failed:", error)
            completion?(error)
        }
    }

    // MARK: - Fetch

    /// Fetches the profile at `profiles/{uid}`; returns nil if not found.
    func fetchProfile(uid: String,
                      completion: @escaping (UserProfile?) -> Void) {

        db.collection("profiles")
            .document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    print("❌ fetchProfile error:", error)
                    completion(nil)
                    return
                }

                guard let data = snapshot?.data() else {
                    print("ℹ️ No profile document for uid:", uid)
                    completion(nil)
                    return
                }

                do {
                    let profile = try self.decode(data)
                    completion(profile)
                } catch {
                    print("❌ Decoding UserProfile error:", error)
                    completion(nil)
                }
            }
    }
}
