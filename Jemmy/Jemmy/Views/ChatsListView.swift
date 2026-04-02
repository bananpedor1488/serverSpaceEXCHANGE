import SwiftUI

struct ChatsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var chats: [ChatListItem] = []
    @State private var isLoading = false
    @State private var selectedChatId: String?
    @State private var selectedOtherUser: Identity?
    @State private var showChat = false
    @State private var searchText = ""
    @State private var showSearchByTag = false
    @Binding var openChat: CreatedChat?
    
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
                            .font(.system(size: 16))
                        
                        TextField("Поиск", text: $searchText)
                            .foregroundColor(.white)
                            .font(.system(size: 17))
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
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
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredChats) { chat in
                                    ChatListRow(chat: chat)
                                        .onTapGesture {
                                            selectedChatId = chat.id
                                            selectedOtherUser = chat.user
                                            showChat = true
                                        }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                        .padding(.leading, 88)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Чаты")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSearchByTag = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                loadChats()
            }
            .refreshable {
                loadChats()
            }
            .onChange(of: openChat) { newValue in
                if let chat = newValue {
                    print("🔔 Opening chat from invite:", chat.chatId)
                    selectedChatId = chat.chatId
                    selectedOtherUser = chat.otherUser
                    showChat = true
                    openChat = nil
                    loadChats()
                }
            }
            .sheet(isPresented: $showChat) {
                if let chatId = selectedChatId, let otherUser = selectedOtherUser {
                    ChatView(chatId: chatId, otherUser: otherUser)
                        .environmentObject(authViewModel)
                }
            }
            .sheet(isPresented: $showSearchByTag) {
                SearchView()
                    .environmentObject(authViewModel)
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
