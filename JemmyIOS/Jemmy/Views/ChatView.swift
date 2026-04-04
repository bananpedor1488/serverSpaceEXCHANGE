import SwiftUI

struct ChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    let chatId: String
    let otherUser: Identity
    
    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var isSending = false
    @State private var pollingTimer: Timer?
    @State private var showProfile = false
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var isOnline = false
    @State private var lastSeen: Int64 = 0
    
    var statusText: String {
        if isOnline {
            return "в сети"
        } else if lastSeen > 0 {
            let date = Date(timeIntervalSince1970: TimeInterval(lastSeen) / 1000)
            let now = Date()
            let diff = now.timeIntervalSince(date)
            let seconds = Int(diff)
            let minutes = seconds / 60
            let hours = minutes / 60
            let days = hours / 24
            
            switch true {
            case seconds < 30:
                return "только что"
            case minutes < 1:
                return "меньше минуты назад"
            case minutes == 1:
                return "минуту назад"
            case minutes < 5:
                return "\(minutes) минуты назад"
            case minutes < 60:
                return "\(minutes) минут назад"
            case hours == 1:
                return "час назад"
            case hours < 5:
                return "\(hours) часа назад"
            case hours < 24:
                return "\(hours) часов назад"
            case days == 1:
                return "вчера"
            case days < 7:
                return "\(days) дней назад"
            default:
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                return formatter.string(from: date)
            }
        } else {
            return "был(а) давно"
        }
    }
    
    var filteredMessages: [ChatMessage] {
        if searchText.isEmpty {
            return messages
        }
        return messages.filter { $0.encryptedContent.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                if showSearch {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                        
                        TextField("Поиск в чате", text: $searchText)
                            .foregroundColor(.white)
                        
                        Button(action: { 
                            withAnimation {
                                showSearch = false
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredMessages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromMe: message.senderIdentityId == authViewModel.identity?.id
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onAppear {
                        // Скроллим вниз при открытии
                        if let lastMessage = messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input
                HStack(spacing: 12) {
                    TextField("Сообщение", text: $messageText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    
                    Button(action: sendMessage) {
                        Image(systemName: isSending ? "hourglass" : "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? .white.opacity(0.3) : .green)
                    }
                    .disabled(messageText.isEmpty || isSending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 0) {
                    Spacer()
                    
                    Button(action: { showProfile = true }) {
                        VStack(spacing: 2) {
                            Text(otherUser.username)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(statusText)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                withAnimation {
                                    showSearch = true
                                }
                            }
                    )
                    
                    Spacer()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showProfile = true }) {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(otherUser.username.prefix(2)).uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                        
                        if isOnline {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showProfile) {
            UserProfileView(user: otherUser)
                .environmentObject(authViewModel)
        }
        .onAppear {
            loadMessagesFromCache()
            loadMessages()
            startPolling()
            setupWebSocket()
            updateUserStatus()
            markMessagesAsRead()
        }
        .onDisappear {
            stopPolling()
            WebSocketManager.shared.onUserStatus = nil
            WebSocketManager.shared.onMessageStatusUpdate = nil
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            if isConnected {
                loadMessages()
                startPolling()
            } else {
                stopPolling()
            }
        }
    }
    
    private func updateUserStatus() {
        isOnline = otherUser.isOnline ?? false
        if let lastSeenDate = otherUser.lastSeenDate {
            lastSeen = Int64(lastSeenDate.timeIntervalSince1970 * 1000)
        }
    }
    
    private func setupWebSocket() {
        WebSocketManager.shared.onUserStatus = { identityId, online, lastSeenTimestamp in
            if identityId == self.otherUser.id {
                self.isOnline = online
                self.lastSeen = lastSeenTimestamp
            }
        }
        
        WebSocketManager.shared.onMessageStatusUpdate = { messageId, delivered, read in
            if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                // Update message status in local array
                // Note: ChatMessage is immutable, so we need to reload or use a mutable wrapper
                self.loadMessages()
            }
        }
        
        // Request initial status
        WebSocketManager.shared.requestUserStatus(identityId: otherUser.id)
    }
    
    private func markMessagesAsRead() {
        guard let myIdentityId = authViewModel.identity?.id else { return }
        
        // Mark all messages from other user as read
        messages
            .filter { $0.senderIdentityId != myIdentityId && !$0.read }
            .forEach { message in
                WebSocketManager.shared.markMessageRead(messageId: message.id, chatId: chatId)
            }
    }
    
    private func startPolling() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task {
                await refreshMessages()
            }
        }
    }
    
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    private func refreshMessages() async {
        do {
            let loadedMessages = try await APIService.shared.getMessages(chatId: chatId)
            
            await MainActor.run {
                if loadedMessages.count > messages.count {
                    messages = loadedMessages
                }
            }
        } catch {
            // Silently fail for polling
        }
    }
    
    private func loadMessagesFromCache() {
        if let cachedMessages = CacheManager.shared.loadMessages(chatId: chatId) {
            messages = cachedMessages
        }
    }
    
    private func loadMessages() {
        guard networkMonitor.isConnected else {
            print("⚠️ No network connection, using cache")
            isLoading = false
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let loadedMessages = try await APIService.shared.getMessages(chatId: chatId)
                
                await MainActor.run {
                    messages = loadedMessages
                    isLoading = false
                    
                    // Сохраняем в кэш
                    CacheManager.shared.saveMessages(loadedMessages, chatId: chatId)
                }
            } catch {
                print("❌ error:", error.localizedDescription)
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func sendMessage() {
        guard let myIdentityId = authViewModel.identity?.id else {
            print("⚠️ Cannot send message: no identity")
            return
        }
        
        guard networkMonitor.isConnected else {
            print("⚠️ Cannot send message: no network")
            return
        }
        
        let text = messageText
        messageText = ""
        isSending = true
        
        Task {
            do {
                let message = try await APIService.shared.sendMessage(
                    chatId: chatId,
                    senderIdentityId: myIdentityId,
                    text: text
                )
                
                await MainActor.run {
                    messages.append(message)
                    isSending = false
                    
                    // Обновляем кэш
                    CacheManager.shared.saveMessages(messages, chatId: chatId)
                }
            } catch {
                print("❌ error:", error.localizedDescription)
                await MainActor.run {
                    messageText = text
                    isSending = false
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromMe: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isFromMe {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 2) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(message.encryptedContent)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(formatTime(message.createdDate))
                        .font(.system(size: 11))
                        .foregroundColor(isFromMe ? .white.opacity(0.7) : .white.opacity(0.5))
                        .padding(.bottom, 1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isFromMe ? Color.green.opacity(0.8) : Color.white.opacity(0.1))
                .cornerRadius(16)
                
                // Статус доставки/прочтения (только для своих сообщений)
                if isFromMe {
                    Text(message.read ? "прочитано" : (message.delivered ? "доставлено" : "отправлено"))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.trailing, 4)
                }
            }
            
            if !isFromMe {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
