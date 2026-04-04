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
    var onUserStatus: ((String, Bool, Int64) -> Void)? // identity_id, online, last_seen
    
    private init() {}
    
    func connect(userId: String, identityId: String) {
        guard let url = URL(string: "http://178.104.40.37:25593") else { 
            print("❌ Invalid WebSocket URL")
            return 
        }
        
        print("🔌 Connecting to WebSocket: http://178.104.40.37:25593")
        print("   User ID: \(userId)")
        print("   Identity ID: \(identityId)")
        
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
        
        socket?.on(clientEvent: .error) { data, ack in
            print("❌ WebSocket error: \(data)")
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
        
        socket?.on("user_status") { [weak self] data, ack in
            print("📊 Received user_status event")
            self?.handleUserStatus(data: data)
        }
        
        socket?.connect()
        print("🔄 WebSocket connecting...")
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
    }
    
    private func register(userId: String, identityId: String) {
        print("📝 Registering with server:")
        print("   Identity ID: \(identityId)")
        socket?.emit("register", ["identity_id": identityId])
    }
    
    func requestUserStatus(identityId: String) {
        print("🔍 Requesting status for: \(identityId)")
        socket?.emit("request_status", ["identity_id": identityId])
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
    
    private func handleUserStatus(data: [Any]) {
        print("📊 handleUserStatus called")
        print("   Raw data: \(data)")
        
        guard let statusData = data.first as? [String: Any] else { 
            print("❌ Failed to parse status data")
            return 
        }
        
        print("   Parsed data: \(statusData)")
        
        guard let identityId = statusData["identity_id"] as? String,
              let online = statusData["online"] as? Bool,
              let lastSeen = statusData["last_seen"] as? Int64 else { 
            print("❌ Missing required fields")
            print("   identity_id: \(statusData["identity_id"] ?? "nil")")
            print("   online: \(statusData["online"] ?? "nil")")
            print("   last_seen: \(statusData["last_seen"] ?? "nil")")
            return 
        }
        
        print("✅ Status parsed successfully:")
        print("   Identity: \(identityId)")
        print("   Online: \(online)")
        print("   Last seen: \(lastSeen)")
        
        DispatchQueue.main.async {
            print("📤 Calling onUserStatus callback")
            self.onUserStatus?(identityId, online, lastSeen)
        }
    }
}
