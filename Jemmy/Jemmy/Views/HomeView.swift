import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatsView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Чаты")
                }
                .tag(0)
            
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
                .tag(1)
        }
        .accentColor(.blue)
    }
}

struct ChatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var chats: [Chat] = []
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    
    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chats
        }
        return chats.filter { chat in
            chat.groupName?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("Поиск", text: $searchText)
                            .foregroundColor(.white)
                            .font(.system(size: 17))
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()
                    
                    // Chats list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredChats) { chat in
                                ChatRow(chat: chat)
                            }
                        }
                        .padding()
                    }
                    
                    if filteredChats.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text(searchText.isEmpty ? "Нет чатов" : "Ничего не найдено")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Чаты")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String((chat.groupName ?? "?").prefix(1)))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.groupName ?? "Чат")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Последнее сообщение...")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showLinkGenerator = false
    @State private var showSearch = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile header
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .blue.opacity(0.5), radius: 30, y: 15)
                                
                                if let identity = authViewModel.identity {
                                    Text(String(identity.username.prefix(2)))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            if let identity = authViewModel.identity {
                                VStack(spacing: 10) {
                                    Text(identity.username)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("#\(identity.tag)")
                                        .font(.system(size: 16, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(10)
                                    
                                    if !identity.bio.isEmpty {
                                        Text(identity.bio)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                            .padding(.top, 8)
                                    }
                                    
                                    if authViewModel.ephemeralEnabled, let expiresAt = identity.expiresAt {
                                        HStack(spacing: 8) {
                                            Image(systemName: "clock.fill")
                                            Text(timeRemaining(until: expiresAt))
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(10)
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
                                    Image(systemName: "link.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Создать ссылку")
                                        .font(.system(size: 17, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.4), radius: 20, y: 10)
                            }
                            
                            Button(action: { showSearch = true }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 20))
                                    Text("Найти по тегу")
                                        .font(.system(size: 17, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }
                            
                            Button(action: { showEditProfile = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 20))
                                    Text("Редактировать профиль")
                                        .font(.system(size: 17, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Settings
                        VStack(spacing: 0) {
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
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ephemeral Identity")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Личность меняется каждые 24 часа")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
            .sheet(isPresented: $showSearch) {
                SearchView()
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private func timeRemaining(until date: Date) -> String {
        let hours = Int(date.timeIntervalSinceNow / 3600)
        return hours > 0 ? "Осталось \(hours)ч" : "Скоро обновится"
    }
}
