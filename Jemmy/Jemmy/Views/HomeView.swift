import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatsView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Чаты")
                }
                .tag(0)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Профиль")
                }
                .tag(1)
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
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 100, height: 100)
                            
                            if let identity = authViewModel.identity {
                                Text(identity.username)
                                    .font(.system(size: 24, weight: .semibold))
                                
                                if authViewModel.ephemeralEnabled, let expiresAt = identity.expiresAt {
                                    Text("⏱ \(timeRemaining(until: expiresAt))")
                                        .font(.system(size: 15))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                Section {
                    Toggle("Ephemeral Identity", isOn: Binding(
                        get: { authViewModel.ephemeralEnabled },
                        set: { _ in
                            Task {
                                await authViewModel.toggleEphemeral()
                            }
                        }
                    ))
                    
                    Text("Личность меняется каждые 24 часа")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Профиль")
        }
    }
    
    private func timeRemaining(until date: Date) -> String {
        let hours = Int(date.timeIntervalSinceNow / 3600)
        return hours > 0 ? "\(hours)ч" : "скоро"
    }
}
