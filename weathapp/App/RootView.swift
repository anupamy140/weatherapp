import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    /// Controls whether we are still on the landing screen or not.
    @State private var showLanding = true

    var body: some View {
        Group {
            if showLanding {
                // 1️⃣ First screen: Landing
                LandingView {
                    // When user taps "Get Started"
                    withAnimation {
                        showLanding = false
                    }
                }

            } else if authViewModel.user == nil {
                // 2️⃣ Not logged in yet → show login/signup
                AuthView()

            } else {
                // 3️⃣ Logged in → show main weather app
                MainTabView() // or whatever your main container view is
            }
        }
        // 🔁 When user logs out, bring them back to Landing
        .onChange(of: authViewModel.user) { newUser in
            if newUser == nil {
                // user became nil → logged out
                showLanding = true
            }
        }
    }
}
