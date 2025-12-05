import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                CityListView()
            }
            .tabItem {
                Label("Home", systemImage: "cloud.sun.fill")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}
