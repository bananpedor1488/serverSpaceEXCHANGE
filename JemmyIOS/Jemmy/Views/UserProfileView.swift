import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    let user: Identity
    
    @State private var selectedTab = 0
    @State private var isOnline = false
    @State private var lastSeen: Int64 = 0
    @State private var showBlockAlert = false
    
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
                        
                        Text(user.username)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(statusText)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                        
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
                            icon: "hand.raised.fill",
                            title: "Заблокировать пользователя",
                            action: {
                                blockUser()
                            }
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
        }
        .onDisappear {
            WebSocketManager.shared.onUserStatus = nil
        }
        .alert("Заблокировать пользователя?", isPresented: $showBlockAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Заблокировать", role: .destructive) {
                performBlock()
            }
        } message: {
            Text("Вы больше не будете получать сообщения от \(user.username)")
        }
    }
    
    private func blockUser() {
        showBlockAlert = true
    }
    
    private func performBlock() {
        Task {
            do {
                guard let currentUserId = authViewModel.currentUser?.id else { return }
                try await APIService.shared.blockUser(blockerIdentityId: currentUserId, blockedIdentityId: user.id)
                dismiss()
            } catch {
                print("❌ Failed to block user: \(error)")
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
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
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
