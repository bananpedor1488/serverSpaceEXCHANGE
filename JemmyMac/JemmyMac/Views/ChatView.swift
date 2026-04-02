import SwiftUI

struct ChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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
    @State private var lastSeen: Date?
    
    var statusText: String {
        if isOnline {
            return "в сети"
        } else if let lastSeen = lastSeen {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.localizedString(for: lastSeen, relativeTo: Date())
        } else {
            return "был(а) недавно"
        }
    }
    
    var filteredMessages: [ChatMessage] {
        if searchText.isEmpty {
            return messages
        }
        return messages.filter { $0.encryptedContent.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            Button(action: { showProfile = true }) {
                HStack(spacing: 12) {
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(otherUser.username)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(statusText)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(otherUser.username.prefix(2)).uppercased())
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black)
            }
            .buttonStyle(.plain)
            
            // Search Bar (if active)
            if showSearch {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 12))
                    
                    TextField("Поиск в чате", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 13))
                    
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
                .padding(.vertical, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Messages
            if isLoading {
                Spacer()
                ProgressView()
                    .controlSize(.large)
                Spacer()
            } else {
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
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Input
            HStack(spacing: 12) {
                TextField("Сообщение", text: $messageText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                    .foregroundColor(.white)
                
                Button(action: sendMessage) {
                    Image(systemName: isSending ? "hourglass" : "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(messageText.isEmpty ? .white.opacity(0.3) : .green)
                }
                .buttonStyle(.plain)
                .disabled(messageText.isEmpty || isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black)
        }
        .background(Color.black)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { 
                    withAnimation {
                        showSearch.toggle()
                        if !showSearch {
                            searchText = ""
                        }
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            UserProfileView(user: otherUser)
                .environmentObject(authViewModel)
                .frame(width: 500, height: 700)
        }
        .onAppear {
            loadMessages()
            startPolling()
            updateUserStatus()
        }
        .onDisappear {
            stopPolling()
        }
    }
    
    private func updateUserStatus() {
        isOnline = otherUser.isOnline ?? false
        lastSeen = otherUser.lastSeenDate
    }
    
    private func startPolling() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
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
                // Only update if there are new messages
                if loadedMessages.count > messages.count {
                    messages = loadedMessages
                }
            }
        } catch {
            // Silently fail for polling
        }
    }
    
    private func loadMessages() {
        isLoading = true
        
        Task {
            do {
                let loadedMessages = try await APIService.shared.getMessages(chatId: chatId)
                
                await MainActor.run {
                    messages = loadedMessages
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
    
    private func sendMessage() {
        guard let myIdentityId = authViewModel.identity?.id else {
            print("⚠️ Cannot send message: no identity")
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
        HStack {
            if isFromMe {
                Spacer()
            }
            
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.encryptedContent)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromMe ? Color.green.opacity(0.8) : Color.white.opacity(0.1))
                    .cornerRadius(16)
                
                Text(formatTime(message.createdDate))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 4)
            }
            
            if !isFromMe {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
