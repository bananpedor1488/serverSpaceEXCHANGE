import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLinkGenerator = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Profile section
                if let identity = authViewModel.identity {
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(identity.username.prefix(2)).uppercased())
                                    .font(.system(size: 24, weight: .semibold))
                            )
                        
                        Text(identity.username)
                            .font(.system(size: 15, weight: .semibold))
                        
                        Button(action: { showLinkGenerator = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                Text("Создать ссылку")
                                    .font(.system(size: 13))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
                
                Divider()
                
                // Chats list
                List {
                    ForEach(authViewModel.chats) { chat in
                        ChatRowView(chat: chat)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 250)
        } detail: {
            // Detail view
            VStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text("Выбери чат")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showLinkGenerator) {
            LinkGeneratorView()
                .environmentObject(authViewModel)
                .frame(width: 500, height: 600)
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String((chat.groupName ?? "?").prefix(1)))
                        .font(.system(size: 18, weight: .medium))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.groupName ?? "Чат")
                    .font(.system(size: 14, weight: .semibold))
                
                Text("Последнее сообщение...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
