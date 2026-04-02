import SwiftUI

@main
struct JemmyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showInviteProfile: (identity: Identity, token: String)? = nil
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    OnboardingView()
                        .environmentObject(authViewModel)
                } else if authViewModel.identity != nil {
                    HomeView()
                        .environmentObject(authViewModel)
                        .sheet(item: Binding(
                            get: { showInviteProfile.map { IdentifiableInvite(identity: $0.identity, token: $0.token) } },
                            set: { showInviteProfile = $0.map { ($0.identity, $0.token) } }
                        )) { invite in
                            InviteProfileView(identity: invite.identity, token: invite.token)
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
        
        // Check if it's a custom scheme: jemmy://invite/{token}
        if url.scheme == "jemmy" && url.host == "invite" {
            let token = url.lastPathComponent
            print("🎫 Invite token from custom scheme: \(token)")
            
            Task {
                do {
                    let identity = try await APIService.shared.useInviteLink(token: token)
                    
                    await MainActor.run {
                        print("✅ Showing invite profile: \(identity.username)")
                        showInviteProfile = (identity, token)
                    }
                } catch {
                    print("❌ Failed to use invite link: \(error.localizedDescription)")
                }
            }
        }
        // Check if it's a Universal Link: https://weeky-six.vercel.app/api/u/{token}
        else if url.host == "weeky-six.vercel.app" && url.path.hasPrefix("/api/u/") {
            let token = url.lastPathComponent
            print("🎫 Invite token from Universal Link: \(token)")
            
            Task {
                do {
                    let identity = try await APIService.shared.useInviteLink(token: token)
                    
                    await MainActor.run {
                        print("✅ Showing invite profile: \(identity.username)")
                        showInviteProfile = (identity, token)
                    }
                } catch {
                    print("❌ Failed to use invite link: \(error.localizedDescription)")
                }
            }
        }
    }
}

// Helper struct to make tuple Identifiable
struct IdentifiableInvite: Identifiable {
    let id = UUID()
    let identity: Identity
    let token: String
}
