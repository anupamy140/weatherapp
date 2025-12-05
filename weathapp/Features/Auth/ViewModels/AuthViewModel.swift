// AuthViewModel.swift
import Foundation
import Combine          // 👈 IMPORTANT: gives you ObservableObject & @Published
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        // Observe auth state
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    // MARK: - Sign Up

    func signUp(
        email: String,
        password: String,
        fullName: String,
        city: String
    ) {
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.handleAuthError(error)
                    return
                }

                guard let user = result?.user else { return }
                self.user = user

                // Create / update profile document in Firestore
                ProfileService.shared.createProfile(
                    uid: user.uid,
                    fullName: fullName,
                    city: city,
                    email: email
                )
            }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.handleAuthError(error)
                    return
                }

                self.user = result?.user
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
        user = nil
    }

    // MARK: - Error handling

    private func handleAuthError(_ error: Error) {
        let nsError = error as NSError
        print("🔥 Firebase Auth error:", nsError)
        errorMessage = nsError.localizedDescription
    }
}
