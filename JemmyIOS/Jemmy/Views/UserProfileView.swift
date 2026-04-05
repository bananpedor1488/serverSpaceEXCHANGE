import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    let user: Identity
    
    @State private var selectedTab = 0
    @State private var isOnline = false
    @State private var lastSeen: Int64 = 0
    @State private var isBlocked = false
    @State private var amIBlocked = false
    @State private var showBlockDialog = false
    @State private var showUnblockDialog = false
    
    var statusText: String {
        if isOnline {
            return "в сети"
        } else if lastSeen > 0 {
            let date = Date(timeIntervalSince1970: TimeInterval(lastSeen) / 1000)
            let now = Date()
            let diff = now.timeIntervalSince(date)
            let seconds = Int(diff)
            let minutes = seconds / 60
            let hours = minutes / 60
            let days = hours / 24
            
            switch true {
            case seconds < 30:
                return "только что"
            case minutes < 1:
                return "меньше минуты назад"
            case minutes == 1:
                return "минуту назад"
            case minutes < 5:
                return "\(minutes) минуты назад"
            case minutes < 60:
                return "\(minutes) минут назад"
            case hours == 1:
                return "час назад"
            case hours < 5:
                return "\(hours) часа назад"
            case hours < 24:
                return "\(hours) часов назад"
            case days == 1:
                return "вчера"
            case days < 7:
                return "\(days) дней назад"
            default:
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                return formatter.string(from: date)
            }
        } else {
            return "был(а) давно"
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar & Info
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            if amIBlocked {
                                // Show placeholder avatar if blocked
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white.opacity(0.3))
                                    )
                            } else {
                                AvatarView(identity: user, size: 100)
                                
                                if isOnline {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: 3)
                                        )
                                        .offset(x: -5, y: -5)
                                }
                            }
                        }
                        
                        Text(user.username)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(amIBlocked ? "был(а) давно" : statusText)
                            .font(.system(size: 15))
                            .foregroundColor(amIBlocked ? .white.opacity(0.6) : (isOnline ? .green : .white.opacity(0.6)))
                        
                        if !user.bio.isEmpty {
                            Text(user.bio)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 24)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        ActionButton(icon: "phone.fill", label: "Позвонить", color: .green)
                        ActionButton(icon: "video.fill", label: "Видео", color: .blue)
                        ActionButton(icon: "bell.fill", label: "Без звука", color: .purple)
                    }
                    .padding(.horizontal, 24)
                    
                    // Settings Section
                    VStack(spacing: 0) {
                        SettingsButton(
                            icon: "bell.fill",
                            title: "Уведомления",
                            action: {}
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 60)
                        
                        SettingsButton(
                            icon: isBlocked ? "checkmark" : "hand.raised.fill",
                            title: isBlocked ? "Разблокировать" : "Заблокировать",
                            action: {
                                if isBlocked {
                                    showUnblockDialog = true
                                } else {
                                    showBlockDialog = true
                                }
                            },
                            textColor: isBlocked ? .blue : .red
                        )
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Media Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Медиа")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Все")
                                    .font(.system(size: 15))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Media Tabs
                        HStack(spacing: 0) {
                            MediaTabButton(title: "Фото", isSelected: selectedTab == 0) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 0
                                }
                            }
                            MediaTabButton(title: "Видео", isSelected: selectedTab == 1) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 1
                                }
                            }
                            MediaTabButton(title: "Файлы", isSelected: selectedTab == 2) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 2
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Media Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2)
                        ], spacing: 2) {
                            ForEach(0..<6, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.white.opacity(0.3))
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .alert("Заблокировать пользователя?", isPresented: $showBlockDialog) {
            Button("Отмена", role: .cancel) {}
            Button("Заблокировать", role: .destructive) {
                performBlock()
            }
        } message: {
            Text("Вы не сможете получать сообщения от @\(user.username)")
        }
        .alert("Разблокировать пользователя?", isPresented: $showUnblockDialog) {
            Button("Отмена", role: .cancel) {}
            Button("Разблокировать") {
                performUnblock()
            }
        } message: {
            Text("Вы сможете снова получать сообщения от @\(user.username)")
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            setupWebSocket()
            updateUserStatus()
            checkIfBlocked()
            checkIfIAmBlocked()
        }
        .onDisappear {
            WebSocketManager.shared.onUserStatus = nil
        }
    }
    
    private func checkIfBlocked() {
        guard let currentIdentityId = authViewModel.identity?.id else {
            print("❌ No current identity ID")
            return
        }
        
        print("🔍 Checking if user \(user.username) (ID: \(user.id)) is blocked by identity \(currentIdentityId)")
        
        Task {
            do {
                let blockedUsers = try await APIService.shared.getBlockedUsers(identityId: currentIdentityId)
                print("📋 Got \(blockedUsers.count) blocked users")
                
                await MainActor.run {
                    let wasBlocked = isBlocked
                    isBlocked = blockedUsers.contains { $0.id == user.id }
                    
                    print("✅ User \(user.username) blocked status: \(isBlocked) (was: \(wasBlocked))")
                    
                    if isBlocked {
                        print("🚫 User IS BLOCKED")
                    } else {
                        print("✅ User IS NOT BLOCKED")
                    }
                }
            } catch {
                print("❌ Failed to check blocked status: \(error)")
                
                // Set to not blocked on error to avoid UI issues
                await MainActor.run {
                    isBlocked = false
                }
            }
        }
    }
    
    private func checkIfIAmBlocked() {
        guard let currentIdentityId = authViewModel.identity?.id else {
            print("❌ No current identity ID")
            return
        }
        
        print("🔍 Checking if I am blocked by \(user.username)")
        
        Task {
            do {
                let blocked = try await APIService.shared.amIBlocked(myIdentityId: currentIdentityId, otherIdentityId: user.id)
                
                await MainActor.run {
                    amIBlocked = blocked
                    print(blocked ? "🚫 I AM BLOCKED by \(user.username)" : "✅ I am NOT blocked")
                }
            } catch {
                print("❌ Failed to check if I am blocked: \(error)")
                await MainActor.run {
                    amIBlocked = false
                }
            }
        }
    }
    
    private func performBlock() {
        guard let currentIdentityId = authViewModel.identity?.id else {
            print("❌ No current identity ID for blocking")
            return
        }
        
        print("🚫 Attempting to block user \(user.username) (ID: \(user.id))")
        
        Task {
            do {
                try await APIService.shared.blockUser(blockerIdentityId: currentIdentityId, blockedIdentityId: user.id)
                print("✅ Block API call successful")
                
                await MainActor.run {
                    isBlocked = true
                    showBlockDialog = false
                    print("✅ UI updated: isBlocked = true")
                    
                    // Refresh blocked users list in WebSocket
                    WebSocketManager.shared.refreshBlockedUsers()
                }
            } catch {
                print("❌ Failed to block user: \(error)")
            }
        }
    }
    
    private func performUnblock() {
        guard let currentIdentityId = authViewModel.identity?.id else {
            print("❌ No current identity ID for unblocking")
            return
        }
        
        print("✅ Attempting to unblock user \(user.username) (ID: \(user.id))")
        
        Task {
            do {
                try await APIService.shared.unblockUser(blockerIdentityId: currentIdentityId, blockedIdentityId: user.id)
                print("✅ Unblock API call successful")
                
                await MainActor.run {
                    isBlocked = false
                    showUnblockDialog = false
                    print("✅ UI updated: isBlocked = false")
                    
                    // Refresh blocked users list in WebSocket
                    WebSocketManager.shared.refreshBlockedUsers()
                }
            } catch {
                print("❌ Failed to unblock user: \(error)")
            }
        }
    }
    
    private func updateUserStatus() {
        isOnline = user.isOnline ?? false
        if let lastSeenDate = user.lastSeenDate {
            lastSeen = Int64(lastSeenDate.timeIntervalSince1970 * 1000)
        }
    }
    
    private func setupWebSocket() {
        // Загружаем lastSeen из кеша при инициализации
        if let cachedLastSeen = CacheManager.shared.getLastSeen(userId: user.id) {
            lastSeen = cachedLastSeen
            print("📦 Loaded lastSeen from cache for \(user.username): \(cachedLastSeen)")
        }
        
        WebSocketManager.shared.onUserStatus = { identityId, online, lastSeenTimestamp in
            if identityId == self.user.id {
                self.isOnline = online
                self.lastSeen = lastSeenTimestamp
            }
        }
        
        // Request initial status
        WebSocketManager.shared.requestUserStatus(identityId: user.id)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                )
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct MediaTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    var textColor: Color = .white
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(textColor == .red ? .red : .blue)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
