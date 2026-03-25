import SwiftUI

@main
struct WarrantyPocketApp: App {
    @StateObject private var manager = PocketManager()

    init() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Theme.bg)
        nav.titleTextAttributes = [.foregroundColor: UIColor(Theme.accent)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.accent)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(Theme.accent)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if manager.onboardingDone { MainView() } else { OnboardingView() }
            }
            .environmentObject(manager)
            .preferredColorScheme(.dark)
        }
    }
}
