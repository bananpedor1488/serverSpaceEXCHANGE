import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @Binding var openChat: CreatedChat?
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ChatsListView(openChat: $openChat)
                    .environmentObject(authViewModel)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                        Text("Чаты")
                    }
                    .tag(0)
                
                ProfileView()
                    .environmentObject(authViewModel)
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "person.crop.square.fill" : "person.crop.square")
                        Text("Профиль")
                    }
                    .tag(1)
            }
            .accentColor(.white)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showLinkGenerator = false
    @State private var showDeleteAlert = false
    @State private var showClearCacheAlert = false
    @State private var isDeleting = false
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // HEADER
                        VStack(spacing: 16) {
                            // Avatar
                            Button(action: {
                                print("📸 Avatar tapped")
                                showImagePicker = true
                            }) {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Group {
                                            if let identity = authViewModel.identity {
                                                Text(String(identity.username.prefix(2)).uppercased())
                                                    .font(.system(size: 40, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                    )
                            }
                            
                            // User info
                            if let identity = authViewModel.identity {
                                VStack(spacing: 4) {
                                    Text(identity.username)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("@\(identity.username)")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    if !identity.bio.isEmpty {
                                        Text(identity.bio)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                            .padding(.top, 8)
                                    }
                                }
                            }
                            
                            // Edit button
                            Button(action: {
                                print("✏️ Edit profile tapped")
                                showEditProfile = true
                            }) {
                                Text("Редактировать")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 60)
                            .padding(.top, 8)
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 32)
                        
                        // SETTINGS SECTIONS
                        VStack(spacing: 24) {
                            // Аккаунт
                            SettingsSection(title: "Аккаунт") {
                                SettingsRow(icon: "link", title: "Создать invite-ссылку", action: {
                                    print("🔗 Create invite link")
                                    showLinkGenerator = true
                                })
                                
                                SettingsRow(icon: "doc.on.doc", title: "Скопировать свою ссылку", action: {
                                    print("📋 Copy my link")
                                    copyMyLink()
                                })
                            }
                            
                            // Приватность
                            SettingsSection(title: "Приватность") {
                                SettingsRow(icon: "eye.slash", title: "Кто может писать", subtitle: "Все", action: {
                                    print("🔒 Privacy settings")
                                })
                                
                                SettingsRow(icon: "person.crop.circle.badge.xmark", title: "Заблокированные", action: {
                                    print("🚫 Blocked users")
                                })
                            }
                            
                            // Чаты
                            SettingsSection(title: "Чаты") {
                                SettingsRow(icon: "trash", title: "Очистить кэш", action: {
                                    print("🗑️ Clear cache")
                                    showClearCacheAlert = true
                                })
                                
                                SettingsRow(icon: "bell.badge", title: "Уведомления", subtitle: "Включены", action: {
                                    print("🔔 Notifications")
                                })
                            }
                            
                            // Ephemeral
                            if authViewModel.ephemeralEnabled, let identity = authViewModel.identity, let expiresAt = identity.expiresAt {
                                SettingsSection(title: "Ephemeral Identity") {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(.orange)
                                        Text("Осталось \(timeRemaining(until: expiresAt))")
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.7))
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Danger zone
                            SettingsSection(title: "Опасная зона") {
                                Button(action: {
                                    print("⚠️ Delete account")
                                    showDeleteAlert = true
                                }) {
                                    HStack {
                                        if isDeleting {
                                            ProgressView()
                                                .tint(.red)
                                        } else {
                                            Image(systemName: "trash")
                                            Text("Удалить аккаунт")
                                        }
                                        Spacer()
                                    }
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .disabled(isDeleting)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditProfile) {
                if let identity = authViewModel.identity {
                    ProfileEditView(identity: identity)
                        .environmentObject(authViewModel)
                }
            }
            .sheet(isPresented: $showLinkGenerator) {
                LinkGeneratorView()
                    .environmentObject(authViewModel)
            }
            .alert("Удалить аккаунт?", isPresented: $showDeleteAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Все ваши данные будут удалены безвозвратно")
            }
            .alert("Очистить кэш?", isPresented: $showClearCacheAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Очистить", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("Локальные данные чатов и сообщений будут удалены")
            }
        }
        .onAppear {
            print("📡 load profile")
        }
    }
    
    private func copyMyLink() {
        guard let identity = authViewModel.identity else { return }
        let link = "https://jemmy.app/u/\(identity.username)"
        UIPasteboard.general.string = link
        print("📋 Copied link: \(link)")
    }
    
    private func clearCache() {
        CacheManager.shared.clearAll()
        print("🗑️ Cache cleared")
    }
    
    private func timeRemaining(until date: Date) -> String {
        let hours = Int(date.timeIntervalSinceNow / 3600)
        return hours > 0 ? "\(hours)ч" : "скоро"
    }
    
    private func deleteAccount() {
        print("📡 delete account")
        isDeleting = true
        
        Task {
            do {
                try await authViewModel.deleteAccount()
                print("✅ Account deleted")
            } catch {
                print("❌ error:", error.localizedDescription)
            }
            
            await MainActor.run {
                isDeleting = false
            }
        }
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                content
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}
