// weathappApp.swift
import SwiftUI
import FirebaseCore

@main
struct weathappApp: App {
    @StateObject private var auth = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
        }
    }
}
