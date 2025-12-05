// ProfileViewModel.swift
import Foundation
import Combine        // 👈 needed for ObservableObject & @Published
import FirebaseAuth

final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false

    // (You can add cancellables later if you use Combine publishers)
    private var cancellables = Set<AnyCancellable>()

    func loadProfile() {
        // Make sure we have a logged-in user
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ No current user in ProfileViewModel.loadProfile()")
            return
        }

        isLoading = true

        ProfileService.shared.fetchProfile(uid: uid) { [weak self] profile in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.profile = profile
                self.isLoading = false
            }
        }
    }
}
