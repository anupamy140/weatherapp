// SettingsViewModel.swift
import Foundation
import Combine              // ← IMPORTANT: needed for @Published & ObservableObject
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SettingsViewModel: ObservableObject {
    // Profile fields
    @Published var fullName: String = ""
    @Published var city: String = ""
    @Published var email: String = ""   // read-only in UI

    // Password change
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""

    // UI state
    @Published var isSavingProfile: Bool = false
    @Published var isChangingPassword: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let db = Firestore.firestore()

    // MARK: - Load current user & profile

    func loadCurrentData() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No logged-in user."
            return
        }

        email = user.email ?? ""

        // Load profile document: profiles/{uid}
        let uid = user.uid
        db.collection("profiles").document(uid).getDocument { snapshot, error in
            Task { @MainActor in
                if let error = error {
                    print("❌ Failed to load profile:", error)
                    self.errorMessage = "Failed to load profile."
                    return
                }

                guard let data = snapshot?.data() else {
                    // No profile yet – leave fields empty
                    return
                }

                self.fullName = data["fullName"] as? String ?? ""
                self.city = data["city"] as? String ?? ""
            }
        }
    }

    // MARK: - Save profile (name + city)

    func saveProfileChanges() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No logged-in user."
            return
        }

        isSavingProfile = true
        errorMessage = nil
        successMessage = nil

        let uid = user.uid
        let updates: [String: Any] = [
            "fullName": fullName,
            "city": city,
            "email": email   // keep in sync
        ]

        db.collection("profiles").document(uid).setData(updates, merge: true) { error in
            Task { @MainActor in
                self.isSavingProfile = false
                if let error = error {
                    print("❌ Failed to save profile:", error)
                    self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                } else {
                    self.successMessage = "Profile updated successfully."
                    print("✅ Profile updated")
                }
            }
        }
    }

    // MARK: - Change password

    func changePassword() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No logged-in user."
            return
        }

        guard !newPassword.isEmpty else {
            errorMessage = "Password cannot be empty."
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isChangingPassword = true
        errorMessage = nil
        successMessage = nil

        user.updatePassword(to: newPassword) { error in
            Task { @MainActor in
                self.isChangingPassword = false
                if let error = error {
                    print("❌ Failed to change password:", error)
                    self.errorMessage = "Failed to change password: \(error.localizedDescription)"
                } else {
                    self.successMessage = "Password updated successfully."
                    self.newPassword = ""
                    self.confirmPassword = ""
                    print("✅ Password updated")
                }
            }
        }
    }
}
