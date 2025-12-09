import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ZStack {
            // Same gradient style as other screens
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.57, blue: 0.98),
                    Color(red: 0.36, green: 0.79, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)

                    profileSection
                    passwordSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }

            if viewModel.isSavingProfile || viewModel.isChangingPassword {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            viewModel.loadCurrentData()
        }
        .alert("Message", isPresented: Binding(
            get: { viewModel.errorMessage != nil || viewModel.successMessage != nil },
            set: { _ in
                viewModel.errorMessage = nil
                viewModel.successMessage = nil
            }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            } else {
                Text(viewModel.successMessage ?? "")
            }
        }
    }

    // MARK: - Profile section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                TextField("Full Name", text: $viewModel.fullName)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)

                TextField("City", text: $viewModel.city)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)

                TextField("Email", text: $viewModel.email)
                    .disabled(true) // just show – not editable here
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(16)
                    .opacity(0.8)

                Button {
                    viewModel.saveProfileChanges()
                } label: {
                    Text("Save Profile")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                }
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(24)
        }
    }

    // MARK: - Password section

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                SecureField("New Password", text: $viewModel.newPassword)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)

                SecureField("Confirm New Password", text: $viewModel.confirmPassword)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)

                Button {
                    viewModel.changePassword()
                } label: {
                    Text("Change Password")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(24)
        }
    }
}
