import SwiftUI

struct ChatsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var chats: [ChatListItem] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showSearchByTag = false
    @State private var selectedChat: ChatListItem?
    @State private var isNavigatingToChat = false
    @Binding var openChat: CreatedChat?
    
    var filteredChats: [ChatListItem] {
        let filtered = searchText.isEmpty ? chats : chats.filter { chat in
            chat.user.username.localizedCaseInsensitiveContains(searchText)
        }
        
        // Сортируем: сначала закрепленные, потом по времени
        return filtered.sorted { chat1, chat2 in
            if chat1.isPinned != chat2.isPinned {
                return chat1.isPinned
            }
            return chat1.lastMessageDate > chat2.lastMessageDate
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
                        List {
                            ForEach(filteredChats) { chat in
                                Button(action: {
                                    selectedChat = chat
                                    markChatAsRead(chat)
                                }) {
                                    ChatListRow(chat: chat)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteChat(chat)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        togglePin(chat)
                                    } label: {
                                        Label(chat.isPinned ? "Открепить" : "Закрепить", 
                                              systemImage: chat.isPinned ? "pin.slash.fill" : "pin.fill")
                                    }
                                    .tint(.blue)
                                    
                                    Button {
                                        toggleMute(chat)
                                    } label: {
                                        Label(chat.isMuted ? "Включить звук" : "Без звука", 
                                              systemImage: chat.isMuted ? "bell.fill" : "bell.slash.fill")
                                    }
                                    .tint(.purple)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 88)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        
                        NavigationLink(
                            destination: selectedChat.map { chat in
                                ChatView(chatId: chat.id, otherUser: chat.user)
                                    .environmentObject(authViewModel)
                                    .onAppear {
                                        isNavigatingToChat = true
                                    }
                                    .onDisappear {
                                        isNavigatingToChat = false
                                    }
                            },
                            isActive: Binding(
                                get: { selectedChat != nil },
                                set: { if !$0 { selectedChat = nil } }
                            )
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    }
                }
            }
            .navigationTitle("Чаты")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(isNavigatingToChat ? .hidden : .visible, for: .tabBar)
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
                NotificationManager.shared.requestPermission()
                updateBadgeCount()
                setupWebSocket()
            }
            .onDisappear {
                WebSocketManager.shared.onUnreadUpdate = nil
                WebSocketManager.shared.onPinUpdate = nil
                WebSocketManager.shared.onMuteUpdate = nil
            }
            .refreshable {
                loadChats()
            }
            .onChange(of: openChat) { newValue in
                if let chat = newValue {
                    print("🔔 Chat created from invite:", chat.chatId)
                    openChat = nil
                    loadChats()
                }
            }
            .sheet(isPresented: $showSearchByTag) {
                SearchView(createdChat: $openChat)
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
                    let oldChats = chats
                    chats = loadedChats
                    isLoading = false
                    
                    // Проверяем новые сообщения
                    checkForNewMessages(oldChats: oldChats, newChats: loadedChats)
                    updateBadgeCount()
                }
            } catch {
                print("❌ error:", error.localizedDescription)
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func checkForNewMessages(oldChats: [ChatListItem], newChats: [ChatListItem]) {
        for newChat in newChats {
            if let oldChat = oldChats.first(where: { $0.id == newChat.id }) {
                // Если количество непрочитанных увеличилось и чат не в муте
                if newChat.unreadCount > oldChat.unreadCount && !newChat.isMuted {
                    NotificationManager.shared.sendLocalNotification(
                        title: newChat.user.username,
                        body: newChat.lastMessage,
                        chatId: newChat.id
                    )
                }
            }
        }
    }
    
    private func updateBadgeCount() {
        let totalUnread = chats.reduce(0) { $0 + ($1.isMuted ? 0 : $1.unreadCount) }
        NotificationManager.shared.setBadgeCount(totalUnread)
    }
    
    private func markChatAsRead(_ chat: ChatListItem) {
        guard let identityId = authViewModel.identity?.id else { return }
        
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].unreadCount = 0
            updateBadgeCount()
            
            Task {
                do {
                    try await APIService.shared.markChatAsRead(chatId: chat.id, identityId: identityId)
                } catch {
                    print("❌ Mark as read error:", error.localizedDescription)
                }
            }
        }
    }
    
    private func setupWebSocket() {
        // Обработка обновлений непрочитанных
        WebSocketManager.shared.onUnreadUpdate = { [weak self] chatId, unreadCount in
            guard let self = self else { return }
            if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                self.chats[index].unreadCount = unreadCount
                self.updateBadgeCount()
            }
        }
        
        // Обработка обновлений закрепления
        WebSocketManager.shared.onPinUpdate = { [weak self] chatId, isPinned in
            guard let self = self else { return }
            if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                self.chats[index].isPinned = isPinned
            }
        }
        
        // Обработка обновлений мута
        WebSocketManager.shared.onMuteUpdate = { [weak self] chatId, isMuted in
            guard let self = self else { return }
            if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                self.chats[index].isMuted = isMuted
                self.updateBadgeCount()
            }
        }
    }
    
    private func deleteChat(_ chat: ChatListItem) {
        print("🗑️ Delete chat:", chat.id)
        
        Task {
            do {
                try await APIService.shared.deleteChat(chatId: chat.id)
                
                await MainActor.run {
                    chats.removeAll { $0.id == chat.id }
                }
            } catch {
                print("❌ Delete error:", error.localizedDescription)
            }
        }
    }
    
    private func togglePin(_ chat: ChatListItem) {
        print("📌 Pin chat:", chat.id)
        
        guard let identityId = authViewModel.identity?.id else { return }
        
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].isPinned.toggle()
            
            Task {
                do {
                    let isPinned = try await APIService.shared.toggleChatPin(chatId: chat.id, identityId: identityId)
                    await MainActor.run {
                        if let idx = chats.firstIndex(where: { $0.id == chat.id }) {
                            chats[idx].isPinned = isPinned
                        }
                    }
                } catch {
                    print("❌ Pin error:", error.localizedDescription)
                    // Откатываем изменение при ошибке
                    await MainActor.run {
                        if let idx = chats.firstIndex(where: { $0.id == chat.id }) {
                            chats[idx].isPinned.toggle()
                        }
                    }
                }
            }
        }
    }
    
    private func toggleMute(_ chat: ChatListItem) {
        print("🔕 Mute chat:", chat.id)
        
        guard let identityId = authViewModel.identity?.id else { return }
        
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index].isMuted.toggle()
            updateBadgeCount()
            
            Task {
                do {
                    let isMuted = try await APIService.shared.toggleChatMute(chatId: chat.id, identityId: identityId)
                    await MainActor.run {
                        if let idx = chats.firstIndex(where: { $0.id == chat.id }) {
                            chats[idx].isMuted = isMuted
                            updateBadgeCount()
                        }
                    }
                } catch {
                    print("❌ Mute error:", error.localizedDescription)
                    // Откатываем изменение при ошибке
                    await MainActor.run {
                        if let idx = chats.firstIndex(where: { $0.id == chat.id }) {
                            chats[idx].isMuted.toggle()
                            updateBadgeCount()
                        }
                    }
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
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(chat.user.username.prefix(2)).uppercased())
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                // Unread badge
                if chat.unreadCount > 0 && !chat.isMuted {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(min(chat.unreadCount, 99))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 4, y: 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Pin icon
                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    
                    Text(chat.user.username)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        // Mute icon
                        if chat.isMuted {
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Text(formatTime(chat.lastMessageDate))
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                HStack {
                    Text(chat.lastMessage.isEmpty ? "Начните переписку" : chat.lastMessage)
                        .font(.system(size: 15))
                        .foregroundColor(chat.unreadCount > 0 ? .white.opacity(0.9) : .white.opacity(0.6))
                        .fontWeight(chat.unreadCount > 0 ? .medium : .regular)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(chat.isPinned ? Color.blue.opacity(0.05) : Color.clear)
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
