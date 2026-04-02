import SwiftUI

@main
struct JemmyMacApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showInviteProfile: (identity: Identity, token: String)? = nil
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.identity != nil {
                    ContentView()
                        .environmentObject(authViewModel)
                        .sheet(item: Binding(
                            get: { showInviteProfile.map { IdentifiableInvite(identity: $0.identity, token: $0.token) } },
                            set: { showInviteProfile = $0.map { ($0.identity, $0.token) } }
                        )) { invite in
                            InviteProfileView(identity: invite.identity, token: invite.token)
                                .environmentObject(authViewModel)
                                .frame(width: 500, height: 600)
                        }
                } else {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
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
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link received: \(url.absoluteString)")
        
        if url.scheme == "jemmy" && url.host == "invite" {
            let token = url.lastPathComponent
            print("🎫 Invite token: \(token)")
            
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
