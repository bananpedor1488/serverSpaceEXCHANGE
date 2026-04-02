import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedView: SidebarItem? = .chats
    
    enum SidebarItem: String, CaseIterable {
        case chats = "Чаты"
        case profile = "Профиль"
        
        var icon: String {
            switch self {
            case .chats: return "bubble.left.and.bubble.right"
            case .profile: return "person.crop.square"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SidebarItem.allCases, id: \.self, selection: $selectedView) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .font(.system(size: 14, weight: .medium))
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            .background(Color(NSColor.windowBackgroundColor))
        } detail: {
            // Detail view
            Group {
                switch selectedView {
                case .chats:
                    ChatsView()
                case .profile:
                    ProfileView()
                case .none:
                    ChatsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct ChatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var chats: [Chat] = []
    @State private var searchText = ""
    @State private var showSearchByTag = false
    
    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chats
        }
        return chats.filter { chat in
            chat.groupName?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Чаты")
                    .font(.system(size: 24, weight: .bold))
                
                Spacer()
                
                Button(action: { showSearchByTag = true }) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Поиск", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Chats list
            if filteredChats.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text(searchText.isEmpty ? "Нет чатов" : "Ничего не найдено")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Button("Найти по тегу") {
                            showSearchByTag = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredChats) { chat in
                            ChatRow(chat: chat)
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showSearchByTag) {
            SearchView()
                .environmentObject(authViewModel)
                .frame(width: 500, height: 600)
        }
    }
}

struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String((chat.groupName ?? "?").prefix(1)))
                        .font(.system(size: 20, weight: .medium))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.groupName ?? "Чат")
                    .font(.system(size: 15, weight: .semibold))
                
                Text("Последнее сообщение...")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("12:34")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .hoverEffect()
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showLinkGenerator = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Profile header
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Group {
                                if let identity = authViewModel.identity {
                                    Text(String(identity.username.prefix(2)).uppercased())
                                        .font(.system(size: 40, weight: .semibold))
                                }
                            }
                        )
                    
                    if let identity = authViewModel.identity {
                        VStack(spacing: 8) {
                            Text(identity.username)
                                .font(.system(size: 28, weight: .semibold))
                            
                            Text("#\(identity.tag)")
                                .font(.system(size: 15, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            if !identity.bio.isEmpty {
                                Text(identity.bio)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                    .padding(.top, 4)
                            }
                            
                            if authViewModel.ephemeralEnabled, let expiresAt = identity.expiresAt {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                    Text(timeRemaining(until: expiresAt))
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(8)
                                .padding(.top, 8)
                            }
                        }
                    }
                }
                .padding(.top, 40)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: { showLinkGenerator = true }) {
                        HStack {
                            Image(systemName: "link")
                            Text("Создать ссылку")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { showEditProfile = true }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Редактировать профиль")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                
                // Settings
                VStack(spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { authViewModel.ephemeralEnabled },
                        set: { _ in
                            Task {
                                await authViewModel.toggleEphemeral()
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 18))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ephemeral Identity")
                                    .font(.system(size: 15, weight: .medium))
                                Text("Личность меняется каждые 24 часа")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    
                    Button(action: { showDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Удалить аккаунт")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showEditProfile) {
            if let identity = authViewModel.identity {
                ProfileEditView(identity: identity)
                    .environmentObject(authViewModel)
                    .frame(width: 500, height: 600)
            }
        }
        .sheet(isPresented: $showLinkGenerator) {
            LinkGeneratorView()
                .environmentObject(authViewModel)
                .frame(width: 500, height: 600)
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
    
    private func timeRemaining(until date: Date) -> String {
        let hours = Int(date.timeIntervalSinceNow / 3600)
        return hours > 0 ? "Осталось \(hours)ч" : "Скоро обновится"
    }
    
    private func deleteAccount() {
        UserDefaults.standard.removeObject(forKey: "device_id")
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        authViewModel.identity = nil
        authViewModel.isAuthenticated = false
    }
}
