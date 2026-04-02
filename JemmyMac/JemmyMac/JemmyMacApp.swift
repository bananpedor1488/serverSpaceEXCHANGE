import SwiftUI

@main
struct JemmyMacApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showInviteProfile: Identity? = nil
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.identity != nil {
                    ContentView()
                        .environmentObject(authViewModel)
                        .sheet(item: $showInviteProfile) { identity in
                            InviteProfileView(identity: identity)
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
                        showInviteProfile = identity
                    }
                } catch {
                    print("❌ Failed to use invite link: \(error.localizedDescription)")
                }
            }
        }
    }
}
