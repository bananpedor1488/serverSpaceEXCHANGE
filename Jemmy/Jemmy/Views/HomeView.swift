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
    @State private var showImagePicker = false
    @State private var showPrivacySettings = false
    @State private var showDataSettings = false
    @State private var showDevicesSettings = false
    @State private var isDeleting = false
    
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
                                    print("📡 create invite")
                                    showLinkGenerator = true
                                })
                            }
                            
                            // Приватность
                            SettingsSection(title: "Настройки") {
                                SettingsRow(icon: "lock.shield", title: "Приватность", action: {
                                    print("🔒 Privacy settings")
                                    showPrivacySettings = true
                                })
                                
                                SettingsRow(icon: "internaldrive", title: "Данные и память", action: {
                                    print("💾 Data settings")
                                    showDataSettings = true
                                })
                                
                                SettingsRow(icon: "iphone.and.ipad", title: "Устройства", action: {
                                    print("📱 Devices")
                                    showDevicesSettings = true
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
            .sheet(isPresented: $showPrivacySettings) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showDataSettings) {
                DataSettingsView()
            }
            .sheet(isPresented: $showDevicesSettings) {
                DevicesSettingsView()
            }
            .alert("Удалить аккаунт?", isPresented: $showDeleteAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Все ваши данные будут удалены безвозвратно")
            }
        }
        .onAppear {
            print("📡 load profile")
        }
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


// MARK: - Privacy Settings

struct PrivacySettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        SettingsSection(title: "Приватность") {
                            SettingsRow(icon: "eye.slash", title: "Кто может писать", subtitle: "Все", action: {
                                print("🔒 Who can message")
                            })
                            
                            SettingsRow(icon: "eye", title: "Кто видит профиль", subtitle: "Все", action: {
                                print("👁️ Who can see profile")
                            })
                            
                            SettingsRow(icon: "person.crop.circle.badge.xmark", title: "Заблокированные", action: {
                                print("🚫 Blocked users")
                            })
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Приватность")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Data Settings

struct DataSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showClearCacheAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        SettingsSection(title: "Данные и память") {
                            SettingsRow(icon: "trash", title: "Очистить кэш", action: {
                                showClearCacheAlert = true
                            })
                            
                            SettingsRow(icon: "arrow.down.circle", title: "Автозагрузка медиа", subtitle: "Wi-Fi", action: {
                                print("📥 Auto download")
                            })
                            
                            SettingsRow(icon: "chart.bar", title: "Использование памяти", action: {
                                print("📊 Storage usage")
                            })
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Данные и память")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
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
    }
    
    private func clearCache() {
        print("📡 clear cache")
        CacheManager.shared.clearAll()
    }
}

// MARK: - Devices Settings

struct DevicesSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        SettingsSection(title: "Устройства") {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "iphone")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Это устройство")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Активно сейчас")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                
                                Text("Менеджер устройств позволит управлять всеми устройствами, подключенными к вашему аккаунту")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding()
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Устройства")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}
