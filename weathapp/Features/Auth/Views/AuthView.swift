// AuthView.swift
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthViewModel

    @State private var isLoginMode = false

    @State private var fullName = ""
    @State private var city = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(colors: [.blue, .teal],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 40)

                Text(isLoginMode ? "Welcome Back" : "Create Account")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    // Only show name + city when signing up
                    if !isLoginMode {
                        TextField("Full Name", text: $fullName)
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)

                        TextField("City", text: $city)
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                    }

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                if let error = auth.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: handlePrimaryButton) {
                    if auth.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text(isLoginMode ? "Log In" : "Sign Up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.white.opacity(0.9))
                .foregroundColor(.blue)
                .cornerRadius(16)
                .padding(.horizontal)

                // Toggle text
                Button {
                    withAnimation {
                        isLoginMode.toggle()
                        auth.errorMessage = nil
                    }
                } label: {
                    Text(
                        isLoginMode
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Log In"
                    )
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                }

                Spacer()
            }
        }
    }

    private func handlePrimaryButton() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            auth.errorMessage = "Please fill in email and password."
            return
        }

        if isLoginMode {
            auth.signIn(email: trimmedEmail, password: trimmedPassword)
        } else {
            let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            let homeCity = city.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !name.isEmpty, !homeCity.isEmpty else {
                auth.errorMessage = "Please enter your name and city."
                return
            }

            auth.signUp(
                email: trimmedEmail,
                password: trimmedPassword,
                fullName: name,
                city: homeCity
            )
        }
    }
}
