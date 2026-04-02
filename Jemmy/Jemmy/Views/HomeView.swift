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
            
            SearchView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Поиск")
                }
                .tag(1)
            
            LinkGeneratorView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "link.circle.fill")
                    Text("Ссылка")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct ChatsView: View {
    @State private var chats: [Chat] = []
    
    var body: some View {
        NavigationView {
            List(chats) { chat in
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                    
                    Text(chat.groupName ?? "Чат")
                        .font(.system(size: 17, weight: .semibold))
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Чаты")
            .overlay {
                if chats.isEmpty {
                    Text("Нет чатов")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(colorScheme == .dark ? .black : .white)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
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
                                    .shadow(color: .blue.opacity(0.3), radius: 20, y: 10)
                                
                                if let identity = authViewModel.identity {
                                    Text(String(identity.username.prefix(2)))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            if let identity = authViewModel.identity {
                                VStack(spacing: 8) {
                                    Text(identity.username)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                    
                                    Text("#\(identity.tag)")
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    if !identity.bio.isEmpty {
                                        Text(identity.bio)
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                            .padding(.top, 4)
                                    }
                                    
                                    if authViewModel.ephemeralEnabled, let expiresAt = identity.expiresAt {
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock.fill")
                                            Text(timeRemaining(until: expiresAt))
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(8)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                            
                            Button(action: { showEditProfile = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Редактировать")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.top, 20)
                        
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
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ephemeral Identity")
                                            .font(.system(size: 17, weight: .medium))
                                        Text("Личность меняется каждые 24 часа")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditProfile) {
                if let identity = authViewModel.identity {
                    ProfileEditView(identity: identity)
                        .environmentObject(authViewModel)
                }
            }
        }
    }
    
    private func timeRemaining(until date: Date) -> String {
        let hours = Int(date.timeIntervalSinceNow / 3600)
        return hours > 0 ? "Осталось \(hours)ч" : "Скоро обновится"
    }
}
