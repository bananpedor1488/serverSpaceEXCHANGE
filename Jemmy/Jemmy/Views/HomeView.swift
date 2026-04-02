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
    @State private var isDeleting = false
    @State private var showPrivacySettings = false
    @State private var showDataSettings = false
    @State private var showDevicesSettings = false
    
    var isNavigatingToSettings: Bool {
        showPrivacySettings || showDataSettings || showDevicesSettings
    }
    
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
                                Button(action: { showPrivacySettings = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "lock.shield")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                            .frame(width: 24)
                                        
                                        Text("Приватность")
                                            .font(.system(size: 17))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { showDataSettings = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "internaldrive")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                            .frame(width: 24)
                                        
                                        Text("Данные и память")
                                            .font(.system(size: 17))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { showDevicesSettings = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "laptopcomputer.and.iphone")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                            .frame(width: 24)
                                        
                                        Text("Устройства")
                                            .font(.system(size: 17))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                
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
            .toolbar(isNavigatingToSettings ? .hidden : .visible, for: .tabBar)
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
            .background(
                ZStack {
                    NavigationLink(destination: PrivacySettingsView(), isActive: $showPrivacySettings) {
                        EmptyView()
                    }
                    NavigationLink(destination: DataSettingsView(), isActive: $showDataSettings) {
                        EmptyView()
                    }
                    NavigationLink(destination: DevicesSettingsView(), isActive: $showDevicesSettings) {
                        EmptyView()
                    }
                }
            )
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
    var body: some View {
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
    }
}

// MARK: - Data Settings

struct DataSettingsView: View {
    @State private var showClearCacheSheet = false
    @State private var isClearing = false
    @State private var cacheSize: Int64 = 0
    @State private var autoDownloadPhotos = true
    @State private var autoDownloadVideos = false
    @State private var autoDownloadFiles = false
    @State private var showStorageBreakdown = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Storage Usage Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "internaldrive.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Использование памяти")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(formatBytes(cacheSize))
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Button(action: { showStorageBreakdown = true }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Storage Progress Bar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Кэш")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(formatBytes(cacheSize))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: min(CGFloat(cacheSize) / 100_000_000 * geometry.size.width, geometry.size.width), height: 8)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cacheSize)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.horizontal, 16)
                    
                    // Clear Cache Button
                    Button(action: { showClearCacheSheet = true }) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Очистить кэш")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Освободить место на устройстве")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    
                    // Auto Download Section
                    SettingsSection(title: "Автозагрузка медиа") {
                        VStack(spacing: 12) {
                            AutoDownloadToggle(
                                icon: "photo.fill",
                                title: "Фото",
                                color: .green,
                                isOn: $autoDownloadPhotos
                            )
                            
                            AutoDownloadToggle(
                                icon: "video.fill",
                                title: "Видео",
                                color: .blue,
                                isOn: $autoDownloadVideos
                            )
                            
                            AutoDownloadToggle(
                                icon: "doc.fill",
                                title: "Файлы",
                                color: .orange,
                                isOn: $autoDownloadFiles
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Network Settings
                    SettingsSection(title: "Сеть") {
                        SettingsRow(icon: "wifi", title: "Только Wi-Fi", subtitle: "Включено", action: {
                            print("📡 Wi-Fi only")
                        })
                        
                        SettingsRow(icon: "arrow.down.circle", title: "Качество загрузки", subtitle: "Высокое", action: {
                            print("📥 Download quality")
                        })
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            
            // Clear Cache Sheet
            if showClearCacheSheet {
                ClearCacheSheet(
                    isPresented: $showClearCacheSheet,
                    isClearing: $isClearing,
                    cacheSize: $cacheSize
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
            
            // Storage Breakdown Sheet
            if showStorageBreakdown {
                StorageBreakdownSheet(
                    isPresented: $showStorageBreakdown,
                    cacheSize: cacheSize
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .navigationTitle("Данные и память")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateCacheSize()
        }
        .animation(.easeInOut(duration: 0.3), value: showClearCacheSheet)
        .animation(.easeInOut(duration: 0.3), value: showStorageBreakdown)
    }
    
    private func calculateCacheSize() {
        // Симуляция расчета размера кэша
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                cacheSize = Int64.random(in: 10_000_000...80_000_000)
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct AutoDownloadToggle: View {
    let icon: String
    let title: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.blue)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ClearCacheSheet: View {
    @Binding var isPresented: Bool
    @Binding var isClearing: Bool
    @Binding var cacheSize: Int64
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    if isClearing {
                        ProgressView()
                            .tint(.red)
                            .scaleEffect(1.5)
                    } else {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                    }
                }
                .padding(.bottom, 20)
                
                // Title
                Text(isClearing ? "Очистка..." : "Очистить кэш?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                // Description
                Text(isClearing ? "Удаление временных файлов" : "Будут удалены все временные файлы и кэшированные данные (\(formatBytes(cacheSize)))")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                
                if !isClearing {
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: clearCache) {
                            Text("Очистить")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }) {
                            Text("Отмена")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isClearing {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                }
        )
    }
    
    private func clearCache() {
        isClearing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            CacheManager.shared.clearAll()
            
            withAnimation {
                cacheSize = 0
                isClearing = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct StorageBreakdownSheet: View {
    @Binding var isPresented: Bool
    let cacheSize: Int64
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Header
                HStack {
                    Text("Детализация памяти")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 12) {
                        StorageItem(
                            icon: "photo.fill",
                            title: "Фото",
                            size: Int64(Double(cacheSize) * 0.4),
                            color: .green,
                            totalSize: cacheSize
                        )
                        
                        StorageItem(
                            icon: "video.fill",
                            title: "Видео",
                            size: Int64(Double(cacheSize) * 0.3),
                            color: .blue,
                            totalSize: cacheSize
                        )
                        
                        StorageItem(
                            icon: "doc.fill",
                            title: "Файлы",
                            size: Int64(Double(cacheSize) * 0.2),
                            color: .orange,
                            totalSize: cacheSize
                        )
                        
                        StorageItem(
                            icon: "ellipsis.circle.fill",
                            title: "Прочее",
                            size: Int64(Double(cacheSize) * 0.1),
                            color: .gray,
                            totalSize: cacheSize
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 450)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
        )
    }
}

struct StorageItem: View {
    let icon: String
    let title: String
    let size: Int64
    let color: Color
    let totalSize: Int64
    
    var percentage: Double {
        totalSize > 0 ? Double(size) / Double(totalSize) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(formatBytes(size))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: size)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Devices Settings

struct DevicesSettingsView: View {
    var body: some View {
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
    }
}
