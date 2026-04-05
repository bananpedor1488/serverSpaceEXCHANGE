import SwiftUI

@main
struct JemmyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var privacyManager = PrivacyManager.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showInviteProfile: (identity: Identity, token: String)? = nil
    @State private var createdChat: CreatedChat? = nil
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if !hasSeenOnboarding {
                        OnboardingView()
                            .environmentObject(authViewModel)
                    } else if authViewModel.isAuthenticated && authViewModel.identity != nil {
                        HomeView(openChat: $createdChat)
                            .environmentObject(authViewModel)
                            .sheet(item: Binding(
                                get: { showInviteProfile.map { IdentifiableInvite(identity: $0.identity, token: $0.token) } },
                                set: { showInviteProfile = $0.map { ($0.identity, $0.token) } }
                            )) { invite in
                                InviteProfileView(
                                    identity: invite.identity,
                                    token: invite.token,
                                    createdChat: $createdChat
                                )
                                .environmentObject(authViewModel)
                            }
                    } else if authViewModel.existingAccount != nil {
                        // Show restore account screen
                        OnboardingView()
                            .environmentObject(authViewModel)
                    } else if !authViewModel.isAuthenticated {
                        // Not authenticated - show onboarding
                        OnboardingView()
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
                
                // Unlock screen overlay
                if privacyManager.requiresAuthentication && privacyManager.isAppLocked {
                    UnlockView()
                        .environmentObject(privacyManager)
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onChange(of: scenePhase) { newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            print("📱 App went to background")
            // Lock app when going to background if PIN is set
            if privacyManager.hasPinCode || privacyManager.isBiometricEnabled {
                privacyManager.lockApp()
            }
            
        case .active:
            print("📱 App became active")
            // App is now active, unlock screen will show if needed
            // Start auto-lock timer when app becomes active (after unlock)
            if !privacyManager.isAppLocked {
                privacyManager.startAutoLockTimer()
            }
            
        case .inactive:
            print("📱 App became inactive")
            
        @unknown default:
            break
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

struct CreatedChat: Equatable {
    let chatId: String
    let otherUser: Identity
    
    static func == (lhs: CreatedChat, rhs: CreatedChat) -> Bool {
        lhs.chatId == rhs.chatId
    }
}
