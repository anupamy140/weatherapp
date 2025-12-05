import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.user == nil {
                AuthView()      // 👈 shows login / signup
            } else {
                MainTabView()   // 👈 weather + profile tabs
            }
        }
    }
}
