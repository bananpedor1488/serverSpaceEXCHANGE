import SwiftUI

struct ChatsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var chats: [ChatListItem] = []
    @State private var isLoading = false
    @State private var selectedChatId: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .controlSize(.large)
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
                List {
                    ForEach(chats) { chat in
                        ChatListRow(chat: chat)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                selectedChatId = chat.id
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Чаты")
        .onAppear {
            loadChats()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: loadChats) {
                    Image(systemName: "arrow.clockwise")
                }
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
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(chat.user.username.prefix(2)).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.user.username)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatTime(chat.lastMessageTime))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(chat.lastMessage.isEmpty ? "Начните переписку" : chat.lastMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
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
