import SwiftUI
import Combine

struct ChatsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var chats: [ChatListItem] = []
    @State private var isLoading = false
    @State private var selectedChatId: String?
    @State private var selectedOtherUser: Identity?
    @State private var searchText = ""
    @State private var showSearchByTag = false
    @Binding var createdChat: CreatedChat?
    
    var filteredChats: [ChatListItem] {
        if searchText.isEmpty {
            return chats
        }
        return chats.filter { chat in
            chat.user.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 14))
                        
                        TextField("Поиск", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                        Spacer()
                    } else if filteredChats.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 64))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text(searchText.isEmpty ? "Нет чатов" : "Ничего не найдено")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredChats) { chat in
                                NavigationLink(
                                    destination: ChatView(chatId: chat.id, otherUser: chat.user)
                                        .environmentObject(authViewModel),
                                    tag: chat.id,
                                    selection: $selectedChatId
                                ) {
                                    ChatListRow(chat: chat)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Чаты")
            .onAppear {
                loadChats()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 8) {
                        Button(action: { showSearchByTag = true }) {
                            Image(systemName: "person.badge.plus")
                        }
                        
                        Button(action: loadChats) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSearchByTag) {
                SearchView(createdChat: $createdChat)
                    .environmentObject(authViewModel)
                    .frame(width: 500, height: 600)
            }
            
            // Empty detail view
            Text("Выберите чат")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
        .onReceive(Just(createdChat)) { newValue in
            if let chat = newValue {
                print("🔔 Opening chat from search:", chat.chatId)
                selectedChatId = chat.chatId
                selectedOtherUser = chat.otherUser
                createdChat = nil
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
                    
                    Text(formatTime(chat.lastMessageDate))
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
