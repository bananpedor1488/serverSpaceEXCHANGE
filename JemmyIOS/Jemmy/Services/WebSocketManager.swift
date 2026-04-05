import Foundation
import SocketIO

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    
    // Blocked users cache
    private var blockedUserIds: Set<String> = []
    private var currentUserId: String?
    
    var onMessageReceived: ((ChatMessage) -> Void)?
    var onUnreadUpdate: ((String, Int) -> Void)?
    var onPinUpdate: ((String, Bool) -> Void)?
    var onMuteUpdate: ((String, Bool) -> Void)?
    var onUserStatus: ((String, Bool, Int64) -> Void)? // identity_id, online, last_seen
    var onMessageStatusUpdate: ((String, Bool, Bool) -> Void)? // message_id, delivered, read
    var onMessagesRead: (([String]) -> Void)? // message_ids
    var onPrivacySettingsChanged: ((String, String, PrivacySettings) -> Void)? // identity_id, username, settings
    var onScreenshotNotification: ((String, String, String) -> Void)? // chat_id, taker_identity_id, taker_username
    var onUserBlocked: ((String, String) -> Void)? // blocker_identity_id, blocked_identity_id
    var onUserUnblocked: ((String, String) -> Void)? // blocker_identity_id, blocked_identity_id
    var onBlockedByUser: ((String) -> Void)? // blocker_identity_id
    var onUnblockedByUser: ((String) -> Void)? // blocker_identity_id
    var onMessageBlocked: ((String, String) -> Void)? // reason, message
    
    private init() {}
    
    func connect(userId: String, identityId: String) {
        guard let url = URL(string: "http://178.104.40.37:25593") else { 
            print("❌ Invalid WebSocket URL")
            return 
        }
        
        print("🔌 Connecting to WebSocket: http://178.104.40.37:25593")
        print("   User ID: \(userId)")
        print("   Identity ID: \(identityId)")
        
        currentUserId = identityId
        loadBlockedUsers(identityId: identityId)
        
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
        
        socket?.on("message_status_update") { [weak self] data, ack in
            print("📬 Received message_status_update event")
            self?.handleMessageStatusUpdate(data: data)
        }
        
        socket?.on("messages_read") { [weak self] data, ack in
            print("📖 Received messages_read event")
            self?.handleMessagesRead(data: data)
        }
        
        socket?.on("privacy_settings_changed") { [weak self] data, ack in
            print("🔒 Received privacy_settings_changed event")
            self?.handlePrivacySettingsChanged(data: data)
        }
        
        socket?.on("screenshot_notification") { [weak self] data, ack in
            print("📸 Received screenshot_notification event")
            self?.handleScreenshotNotification(data: data)
        }
        
        socket?.on("user_blocked") { [weak self] data, ack in
            print("🚫 Received user_blocked event")
            self?.handleUserBlocked(data: data)
        }
        
        socket?.on("user_unblocked") { [weak self] data, ack in
            print("✅ Received user_unblocked event")
            self?.handleUserUnblocked(data: data)
        }
        
        socket?.on("blocked_by_user") { [weak self] data, ack in
            print("🚫 Received blocked_by_user event")
            self?.handleBlockedByUser(data: data)
        }
        
        socket?.on("unblocked_by_user") { [weak self] data, ack in
            print("✅ Received unblocked_by_user event")
            self?.handleUnblockedByUser(data: data)
        }
        
        socket?.on("message_blocked") { [weak self] data, ack in
            print("🚫 Received message_blocked event")
            self?.handleMessageBlocked(data: data)
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
        let clientTime = Int64(Date().timeIntervalSince1970 * 1000)
        
        socket?.emit("send_message", [
            "chat_id": chatId,
            "sender_identity_id": senderIdentityId,
            "encrypted_content": content,
            "type": "text",
            "client_time": clientTime
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
    
    func markMessageDelivered(messageId: String, chatId: String) {
        socket?.emit("message_delivered", ["message_id": messageId, "chat_id": chatId])
        print("✅ Marked message as delivered: \(messageId)")
    }
    
    func markMessageRead(messageId: String, chatId: String) {
        socket?.emit("message_read", ["message_id": messageId, "chat_id": chatId])
        print("✅ Marked message as read: \(messageId)")
    }
    
    func markMessagesRead(messageIds: [String], chatId: String) {
        socket?.emit("messages_read", ["message_ids": messageIds, "chat_id": chatId])
        print("📖 Marked \(messageIds.count) messages as read in chat \(chatId)")
    }
    
    func sendScreenshotNotification(chatId: String, takerIdentityId: String, takerUsername: String) {
        socket?.emit("screenshot_taken", [
            "chat_id": chatId,
            "taker_identity_id": takerIdentityId,
            "taker_username": takerUsername
        ])
        print("📸 Sent screenshot notification for chat \(chatId)")
    }
    
    private func handleMessageReceived(data: [Any]) {
        guard let messageData = data.first as? [String: Any] else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
            
            // Check if sender is blocked
            if blockedUserIds.contains(message.senderIdentityId) {
                print("🚫 Message from blocked user \(message.senderIdentityId) - IGNORING")
                return
            }
            
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
        
        // Сохраняем lastSeen в кеш
        if lastSeen > 0 {
            CacheManager.shared.saveLastSeen(userId: identityId, lastSeen: lastSeen)
        }
        
        DispatchQueue.main.async {
            print("📤 Calling onUserStatus callback")
            self.onUserStatus?(identityId, online, lastSeen)
        }
    }
    
    private func handleMessageStatusUpdate(data: [Any]) {
        guard let updateData = data.first as? [String: Any],
              let messageId = updateData["message_id"] as? String,
              let delivered = updateData["delivered"] as? Bool,
              let read = updateData["read"] as? Bool else { 
            print("❌ Failed to parse message status update")
            return 
        }
        
        print("✅ Message status update parsed:")
        print("   Message ID: \(messageId)")
        print("   Delivered: \(delivered)")
        print("   Read: \(read)")
        
        DispatchQueue.main.async {
            self.onMessageStatusUpdate?(messageId, delivered, read)
        }
    }
    
    private func handleMessagesRead(data: [Any]) {
        guard let updateData = data.first as? [String: Any],
              let messageIds = updateData["message_ids"] as? [String] else { 
            print("❌ Failed to parse messages read event")
            return 
        }
        
        print("✅ Messages read event parsed: \(messageIds.count) messages")
        
        DispatchQueue.main.async {
            self.onMessagesRead?(messageIds)
        }
    }
    
    private func handlePrivacySettingsChanged(data: [Any]) {
        guard let updateData = data.first as? [String: Any],
              let identityId = updateData["identity_id"] as? String,
              let username = updateData["username"] as? String,
              let settingsData = updateData["privacy_settings"] as? [String: Any] else { 
            print("❌ Failed to parse privacy_settings_changed event")
            return 
        }
        
        print("✅ Privacy settings changed event parsed for \(username)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: settingsData)
            let settings = try JSONDecoder().decode(PrivacySettings.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.onPrivacySettingsChanged?(identityId, username, settings)
            }
        } catch {
            print("❌ Error decoding privacy settings:", error)
        }
    }
    
    private func handleScreenshotNotification(data: [Any]) {
        guard let notificationData = data.first as? [String: Any],
              let chatId = notificationData["chat_id"] as? String,
              let takerIdentityId = notificationData["taker_identity_id"] as? String,
              let takerUsername = notificationData["taker_username"] as? String else { 
            print("❌ Failed to parse screenshot_notification event")
            return 
        }
        
        print("✅ Screenshot notification parsed: \(takerUsername) took screenshot in chat \(chatId)")
        
        DispatchQueue.main.async {
            self.onScreenshotNotification?(chatId, takerIdentityId, takerUsername)
        }
    }
    
    private func handleUserBlocked(data: [Any]) {
        guard let blockData = data.first as? [String: Any],
              let blockerIdentityId = blockData["blocker_identity_id"] as? String,
              let blockedIdentityId = blockData["blocked_identity_id"] as? String else { 
            print("❌ Failed to parse user_blocked event")
            return 
        }
        
        print("✅ User blocked event parsed: \(blockerIdentityId) blocked \(blockedIdentityId)")
        
        DispatchQueue.main.async {
            self.onUserBlocked?(blockerIdentityId, blockedIdentityId)
        }
    }
    
    private func handleUserUnblocked(data: [Any]) {
        guard let unblockData = data.first as? [String: Any],
              let blockerIdentityId = unblockData["blocker_identity_id"] as? String,
              let blockedIdentityId = unblockData["blocked_identity_id"] as? String else { 
            print("❌ Failed to parse user_unblocked event")
            return 
        }
        
        print("✅ User unblocked event parsed: \(blockerIdentityId) unblocked \(blockedIdentityId)")
        
        DispatchQueue.main.async {
            self.onUserUnblocked?(blockerIdentityId, blockedIdentityId)
        }
    }
    
    private func handleBlockedByUser(data: [Any]) {
        guard let blockData = data.first as? [String: Any],
              let blockerIdentityId = blockData["blocker_identity_id"] as? String else { 
            print("❌ Failed to parse blocked_by_user event")
            return 
        }
        
        print("✅ Blocked by user event parsed: blocked by \(blockerIdentityId)")
        
        DispatchQueue.main.async {
            self.onBlockedByUser?(blockerIdentityId)
        }
    }
    
    private func handleUnblockedByUser(data: [Any]) {
        guard let unblockData = data.first as? [String: Any],
              let blockerIdentityId = unblockData["blocker_identity_id"] as? String else { 
            print("❌ Failed to parse unblocked_by_user event")
            return 
        }
        
        print("✅ Unblocked by user event parsed: unblocked by \(blockerIdentityId)")
        
        DispatchQueue.main.async {
            self.onUnblockedByUser?(blockerIdentityId)
        }
    }
    
    private func handleMessageBlocked(data: [Any]) {
        guard let blockData = data.first as? [String: Any],
              let reason = blockData["reason"] as? String,
              let message = blockData["message"] as? String else { 
            print("❌ Failed to parse message_blocked event")
            return 
        }
        
        print("✅ Message blocked event parsed: \(reason) - \(message)")
        
        DispatchQueue.main.async {
            self.onMessageBlocked?(reason, message)
        }
    }
    
    private func loadBlockedUsers(identityId: String) {
        Task {
            do {
                let blockedUsers = try await APIService.shared.getBlockedUsers(identityId: identityId)
                await MainActor.run {
                    self.blockedUserIds = Set(blockedUsers.map { $0.id })
                    print("📋 Loaded \(self.blockedUserIds.count) blocked users")
                }
            } catch {
                print("❌ Failed to load blocked users: \(error)")
            }
        }
    }
    
    func refreshBlockedUsers() {
        guard let userId = currentUserId else { return }
        loadBlockedUsers(identityId: userId)
    }
}
