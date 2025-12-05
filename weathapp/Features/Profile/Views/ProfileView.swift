// ProfileView.swift
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()

    // Temp fields used when profile does not exist yet
    @State private var tempFullName: String = ""
    @State private var tempCity: String = ""
    @State private var isSavingProfile = false
    @State private var saveErrorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .teal],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Loading profile...")
                        .tint(.white)
                } else if let p = viewModel.profile {
                    // ✅ Profile exists – show data
                    Text("My Profile")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name: \(p.fullName)")
                        Text("City: \(p.city)")
                        Text("Email: \(p.email)")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)

                    Spacer()

                    Button(role: .destructive) {
                        auth.signOut()
                    } label: {
                        Text("Log Out")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                } else {
                    // ❌ No profile doc yet – let user create one
                    if let user = auth.user {
                        Text("No profile found")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(spacing: 12) {
                            TextField("Full Name", text: $tempFullName)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)

                            TextField("City", text: $tempCity)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)

                            // Email is known from auth, show as read-only
                            Text(user.email ?? "")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(10)

                            if let error = saveErrorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }

                            Button {
                                createProfileForCurrentUser(user: user)
                            } label: {
                                if isSavingProfile {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Save Profile")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                        }
                        .padding()

                        Spacer()

                        Button(role: .destructive) {
                            auth.signOut()
                        } label: {
                            Text("Log Out")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                    } else {
                        // Very unlikely: no auth user
                        Text("You are not logged in.")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.loadProfile()
            preloadTempFieldsFromAuth()
        }
    }

    // Pre-fill temp fields with something nice
    private func preloadTempFieldsFromAuth() {
        guard let user = auth.user else { return }
        if tempFullName.isEmpty {
            // default: part of email before "@"
            if let email = user.email,
               let namePart = email.split(separator: "@").first {
                tempFullName = String(namePart)
            }
        }
    }

    private func createProfileForCurrentUser(user: User) {
        let name = tempFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = tempCity.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty, !city.isEmpty else {
            saveErrorMessage = "Please enter your name and city."
            return
        }

        isSavingProfile = true
        saveErrorMessage = nil

        let email = user.email ?? ""

        ProfileService.shared.createProfile(
            uid: user.uid,
            fullName: name,
            city: city,
            email: email
        ) { error in
            DispatchQueue.main.async {
                self.isSavingProfile = false
                if let error = error {
                    self.saveErrorMessage = error.localizedDescription
                } else {
                    // reload profile from Firestore so UI shows it
                    self.viewModel.loadProfile()
                }
            }
        }
    }
}
