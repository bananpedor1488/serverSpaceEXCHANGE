import SwiftUI

struct BlockedUsersView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var blockedUsers: [Identity] = []
    @State private var isLoading = true
    @State private var showUnblockAlert = false
    @State private var userToUnblock: Identity?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else if blockedUsers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Нет заблокированных")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(blockedUsers) { user in
                            BlockedUserCard(user: user) {
                                userToUnblock = user
                                showUnblockAlert = true
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Заблокированные")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadBlockedUsers()
        }
        .alert("Разблокировать пользователя?", isPresented: $showUnblockAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Разблокировать", role: .destructive) {
                if let user = userToUnblock {
                    unblockUser(user)
                }
            }
        } message: {
            if let user = userToUnblock {
                Text("Вы сможете снова получать сообщения от @\(user.username)")
            }
        }
    }
    
    private func loadBlockedUsers() {
        guard let identity = authViewModel.identity else { return }
        
        Task {
            do {
                let users = try await APIService.shared.getBlockedUsers(identityId: identity.id)
                await MainActor.run {
                    blockedUsers = users
                    isLoading = false
                }
            } catch {
                print("❌ Failed to load blocked users:", error)
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func unblockUser(_ user: Identity) {
        guard let identity = authViewModel.identity else { return }
        
        Task {
            do {
                try await APIService.shared.unblockUser(
                    blockerIdentityId: identity.id,
                    blockedIdentityId: user.id
                )
                
                await MainActor.run {
                    blockedUsers.removeAll { $0.id == user.id }
                }
            } catch {
                print("❌ Failed to unblock user:", error)
            }
        }
    }
}

struct BlockedUserCard: View {
    let user: Identity
    let onUnblock: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            AvatarView(identity: user, size: 56)
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Unblock button
            Button(action: onUnblock) {
                Text("Разблокировать")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}
