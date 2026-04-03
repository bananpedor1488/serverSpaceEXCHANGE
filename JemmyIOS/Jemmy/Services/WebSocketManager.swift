import Foundation
import SocketIO

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    
    var onMessageReceived: ((ChatMessage) -> Void)?
    var onUnreadUpdate: ((String, Int) -> Void)?
    var onPinUpdate: ((String, Bool) -> Void)?
    var onMuteUpdate: ((String, Bool) -> Void)?
    
    private init() {}
    
    func connect(userId: String, identityId: String) {
        guard let url = URL(string: APIService.shared.baseURL) else { return }
        
        manager = SocketManager(socketURL: url, config: [.log(false), .compress])
        socket = manager?.defaultSocket
        
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ WebSocket connected")
            self?.isConnected = true
            self?.register(userId: userId, identityId: identityId)
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("❌ WebSocket disconnected")
            self?.isConnected = false
        }
        
        socket?.on("receive_message") { [weak self] data, ack in
            self?.handleMessageReceived(data: data)
        }
        
        socket?.on("unread_update") { [weak self] data, ack in
            self?.handleUnreadUpdate(data: data)
        }
        
        socket?.on("pin_update") { [weak self] data, ack in
            self?.handlePinUpdate(data: data)
        }
        
        socket?.on("mute_update") { [weak self] data, ack in
            self?.handleMuteUpdate(data: data)
        }
        
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
    }
    
    private func register(userId: String, identityId: String) {
        socket?.emit("register", ["user_id": userId, "identity_id": identityId])
    }
    
    func joinChat(chatId: String) {
        socket?.emit("join_chat", ["chat_id": chatId])
    }
    
    func sendMessage(chatId: String, senderIdentityId: String, content: String) {
        socket?.emit("send_message", [
            "chat_id": chatId,
            "sender_identity_id": senderIdentityId,
            "encrypted_content": content,
            "type": "text"
        ])
    }
    
    func markAsRead(chatId: String, identityId: String) {
        socket?.emit("mark_read", ["chat_id": chatId, "identity_id": identityId])
    }
    
    func togglePin(chatId: String, identityId: String) {
        socket?.emit("toggle_pin", ["chat_id": chatId, "identity_id": identityId])
    }
    
    func toggleMute(chatId: String, identityId: String) {
        socket?.emit("toggle_mute", ["chat_id": chatId, "identity_id": identityId])
    }
    
    private func handleMessageReceived(data: [Any]) {
        guard let messageData = data.first as? [String: Any] else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.onMessageReceived?(message)
            }
        } catch {
            print("❌ Error decoding message:", error)
        }
    }
    
    private func handleUnreadUpdate(data: [Any]) {
        guard let updateData = data.first as? [String: Any],
              let chatId = updateData["chat_id"] as? String,
              let unreadCount = updateData["unread_count"] as? Int else { return }
        
        DispatchQueue.main.async {
            self.onUnreadUpdate?(chatId, unreadCount)
        }
    }
    
    private func handlePinUpdate(data: [Any]) {
        guard let updateData = data.first as? [String: Any],
              let chatId = updateData["chat_id"] as? String,
              let isPinned = updateData["is_pinned"] as? Bool else { return }
        
        DispatchQueue.main.async {
            self.onPinUpdate?(chatId, isPinned)
        }
    }
    
    private func handleMuteUpdate(data: [Any]) {
        guard let updateData = data.first as? [String: Any],
              let chatId = updateData["chat_id"] as? String,
              let isMuted = updateData["is_muted"] as? Bool else { return }
        
        DispatchQueue.main.async {
            self.onMuteUpdate?(chatId, isMuted)
        }
    }
}
