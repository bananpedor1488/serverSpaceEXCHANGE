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
    @Environment(\.dismiss) var dismiss
    
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
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar (if active)
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
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
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
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: { showProfile = true }) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(otherUser.username)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(statusText)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
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
                    .frame(maxWidth: .infinity)
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
            }
        }
        .sheet(isPresented: $showProfile) {
            UserProfileView(user: otherUser)
                .environmentObject(authViewModel)
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
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromMe ? Color.green.opacity(0.8) : Color.white.opacity(0.1))
                    .cornerRadius(16)
                
                Text(formatTime(message.createdDate))
                    .font(.system(size: 12))
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
