import SwiftUI

struct ChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let chatId: String
    let otherUser: Identity
    
    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var isSending = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(otherUser.username.prefix(2)).uppercased())
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    Text(otherUser.username)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
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
                                ForEach(messages) { message in
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
        .navigationBarHidden(true)
        .onAppear {
            loadMessages()
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
                
                Text(formatTime(message.createdAt))
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
