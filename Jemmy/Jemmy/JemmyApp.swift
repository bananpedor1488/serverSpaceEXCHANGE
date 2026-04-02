import SwiftUI

@main
struct JemmyApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeView()
                    .environmentObject(AuthViewModel())
            } else {
                OnboardingView()
            }
        }
    }
}
