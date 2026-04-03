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

// MARK: - Devices Settings

struct DevicesSettingsView: View {
    @State private var devices: [Device] = []
    @State private var showTerminateAllSheet = false
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Current device
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ТЕКУЩЕЕ УСТРОЙСТВО")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                        
                        DeviceCard(
                            device: getCurrentDevice(),
                            isCurrent: true,
                            onTerminate: {}
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // Other devices
                    if !devices.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("АКТИВНЫЕ СЕССИИ")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(devices) { device in
                                    DeviceCard(
                                        device: device,
                                        isCurrent: false,
                                        onTerminate: {
                                            terminateDevice(device)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // Terminate all button
                        Button(action: { showTerminateAllSheet = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                
                                Text("Завершить все сессии")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Info text
                    Text("Завершите сессии на устройствах, которыми вы больше не пользуетесь")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
            
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
            
            // Terminate all sheet
            if showTerminateAllSheet {
                TerminateAllSheet(
                    isPresented: $showTerminateAllSheet,
                    onConfirm: terminateAllDevices
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .navigationTitle("Устройства")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDevices()
        }
        .animation(.easeInOut(duration: 0.3), value: showTerminateAllSheet)
    }
    
    private func getCurrentDevice() -> Device {
        let deviceName = UIDevice.current.name
        let systemVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        return Device(
            id: "current",
            name: deviceName,
            type: .iOS,
            systemVersion: "iOS \(systemVersion)",
            appVersion: "v\(appVersion)",
            lastActive: Date(),
            location: nil
        )
    }
    
    private func loadDevices() {
        isLoading = true
        
        // Simulate loading devices
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Mock data - replace with actual API call
            devices = [
                Device(
                    id: "1",
                    name: "MacBook Pro",
                    type: .macOS,
                    systemVersion: "macOS 14.2",
                    appVersion: "v1.0.5",
                    lastActive: Date().addingTimeInterval(-3600),
                    location: "Москва, Россия"
                ),
                Device(
                    id: "2",
                    name: "iPad Air",
                    type: .iOS,
                    systemVersion: "iOS 17.3",
                    appVersion: "v1.0.4",
                    lastActive: Date().addingTimeInterval(-86400),
                    location: "Санкт-Петербург, Россия"
                )
            ]
            isLoading = false
        }
    }
    
    private func terminateDevice(_ device: Device) {
        withAnimation {
            devices.removeAll { $0.id == device.id }
        }
        print("🔴 Terminated device: \(device.name)")
    }
    
    private func terminateAllDevices() {
        withAnimation {
            devices.removeAll()
        }
        print("🔴 Terminated all devices")
    }
}

struct Device: Identifiable {
    let id: String
    let name: String
    let type: DeviceType
    let systemVersion: String
    let appVersion: String
    let lastActive: Date
    let location: String?
    
    enum DeviceType {
        case iOS
        case macOS
        case web
        
        var icon: String {
            switch self {
            case .iOS: return "iphone"
            case .macOS: return "laptopcomputer"
            case .web: return "globe"
            }
        }
        
        var color: Color {
            switch self {
            case .iOS: return .blue
            case .macOS: return .purple
            case .web: return .green
            }
        }
    }
    
    var lastActiveText: String {
        let interval = Date().timeIntervalSince(lastActive)
        
        if interval < 60 {
            return "Активно сейчас"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) мин назад"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) ч назад"
        } else {
            let days = Int(interval / 86400)
            return "\(days) дн назад"
        }
    }
}

struct DeviceCard: View {
    let device: Device
    let isCurrent: Bool
    let onTerminate: () -> Void
    
    @State private var showTerminateSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Device icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(device.type.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: device.type.icon)
                        .font(.system(size: 26))
                        .foregroundColor(device.type.color)
                }
                
                // Device info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(device.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if isCurrent {
                            Text("Это устройство")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                    
                    Text("\(device.systemVersion) • \(device.appVersion)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(device.lastActiveText)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if !isCurrent {
                    Button(action: { showTerminateSheet = true }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .padding(16)
            
            if let location = device.location {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 88)
                
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(location)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .sheet(isPresented: $showTerminateSheet) {
            TerminateDeviceSheet(
                isPresented: $showTerminateSheet,
                deviceName: device.name,
                onConfirm: onTerminate
            )
        }
    }
}

struct TerminateDeviceSheet: View {
    @Binding var isPresented: Bool
    let deviceName: String
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }
                .padding(.bottom, 20)
                
                // Title
                Text("Завершить сессию?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 12)
                
                // Description
                Text("Устройство \"\(deviceName)\" будет отключено от вашего аккаунта")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onConfirm()
                        isPresented = false
                    }) {
                        Text("Завершить")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.red)
                            .cornerRadius(14)
                    }
                    
                    Button(action: { isPresented = false }) {
                        Text("Отмена")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
        )
    }
}

struct TerminateAllSheet: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }
                .padding(.bottom, 20)
                
                // Title
                Text("Завершить все сессии?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 12)
                
                // Description
                Text("Все устройства, кроме текущего, будут отключены от вашего аккаунта")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onConfirm()
                        isPresented = false
                    }) {
                        Text("Завершить все")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.red)
                            .cornerRadius(14)
                    }
                    
                    Button(action: { isPresented = false }) {
                        Text("Отмена")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
        )
    }
}
