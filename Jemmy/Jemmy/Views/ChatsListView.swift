import SwiftUI

struct ChatsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var chats: [ChatListItem] = []
    @State private var isLoading = false
    @State private var selectedChatId: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if chats.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 64))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Нет чатов")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(chats) { chat in
                                ChatListRow(chat: chat)
                                    .onTapGesture {
                                        selectedChatId = chat.id
                                    }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 88)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Чаты")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadChats()
            }
            .refreshable {
                loadChats()
            }
        }
    }
    
    private func loadChats() {
        guard let identityId = authViewModel.identity?.id else {
            print("⚠️ Cannot load chats: no identity")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let loadedChats = try await APIService.shared.getChats(identityId: identityId)
                
                await MainActor.run {
                    chats = loadedChats
                    isLoading = false
                }
            } catch {
                print("❌ error:", error.localizedDescription)
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct ChatListRow: View {
    let chat: ChatListItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(chat.user.username.prefix(2)).uppercased())
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.user.username)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatTime(chat.lastMessageTime))
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(chat.lastMessage.isEmpty ? "Начните переписку" : chat.lastMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            return "вчера"
        } else {
            formatter.dateFormat = "dd.MM.yy"
        }
        
        return formatter.string(from: date)
    }
}
