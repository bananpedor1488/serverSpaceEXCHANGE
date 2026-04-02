import SwiftUI

@main
struct JemmyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    OnboardingView()
                        .environmentObject(authViewModel)
                } else if authViewModel.identity != nil {
                    HomeView()
                        .environmentObject(authViewModel)
                } else {
                    // Loading state - registering user
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            
                            Text("Загрузка...")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .task {
                        print("🚀 App launched, registering user...")
                        await authViewModel.register()
                    }
                }
            }
        }
    }
}
