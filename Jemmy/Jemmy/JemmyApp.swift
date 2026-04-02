import SwiftUI

@main
struct JemmyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showInviteProfile: Identity? = nil
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    OnboardingView()
                        .environmentObject(authViewModel)
                } else if authViewModel.identity != nil {
                    HomeView()
                        .environmentObject(authViewModel)
                        .sheet(item: $showInviteProfile) { identity in
                            InviteProfileView(identity: identity)
                                .environmentObject(authViewModel)
                        }
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
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link received: \(url.absoluteString)")
        
        // Check if it's an invite link: https://weeky-six.vercel.app/api/u/{token}
        if url.host == "weeky-six.vercel.app" && url.path.hasPrefix("/api/u/") {
            let token = url.lastPathComponent
            print("🎫 Invite token: \(token)")
            
            Task {
                do {
                    let identity = try await APIService.shared.useInviteLink(token: token)
                    
                    await MainActor.run {
                        print("✅ Showing invite profile: \(identity.username)")
                        showInviteProfile = identity
                    }
                } catch {
                    print("❌ Failed to use invite link: \(error.localizedDescription)")
                }
            }
        }
    }
}
