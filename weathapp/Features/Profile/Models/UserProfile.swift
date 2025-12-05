// UserProfile.swift
import Foundation

/// Model for user data stored in Firestore under: profiles/{uid}
struct UserProfile: Codable, Identifiable {
    var id: String { uid }

    let uid: String
    let fullName: String
    let city: String
    let email: String
}
