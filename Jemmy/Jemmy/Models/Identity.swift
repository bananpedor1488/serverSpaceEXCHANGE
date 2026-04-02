import Foundation

struct Identity: Codable, Identifiable {
    let id: String
    let username: String
    let avatar: String
    let bio: String
    let expiresAt: Date?
    let isOnline: Bool?
    let lastSeen: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case avatar
        case bio
        case expiresAt = "expires_at"
        case isOnline = "is_online"
        case lastSeen = "last_seen"
    }
    
    var lastSeenDate: Date? {
        guard let lastSeen = lastSeen else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: lastSeen)
    }
}

struct AuthResponse: Codable {
    let userId: String
    let identity: Identity
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case identity
    }
}

struct ChatStartResponse: Codable {
    let chatId: String
    let otherUser: Identity
    
    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case otherUser = "other_user"
    }
}

struct ChatListItem: Codable, Identifiable {
    let id: String
    let lastMessage: String
    let lastMessageTime: String
    let user: Identity
    var isPinned: Bool
    var unreadCount: Int
    var isMuted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case lastMessage
        case lastMessageTime
        case user
        case isPinned = "is_pinned"
        case unreadCount = "unread_count"
        case isMuted = "is_muted"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        lastMessageTime = try container.decode(String.self, forKey: .lastMessageTime)
        user = try container.decode(Identity.self, forKey: .user)
        isPinned = (try? container.decode(Bool.self, forKey: .isPinned)) ?? false
        unreadCount = (try? container.decode(Int.self, forKey: .unreadCount)) ?? 0
        isMuted = (try? container.decode(Bool.self, forKey: .isMuted)) ?? false
    }
    
    var lastMessageDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: lastMessageTime) ?? Date()
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let chatId: String
    let senderIdentityId: String
    let encryptedContent: String
    let type: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case chatId = "chat_id"
        case senderIdentityId = "sender_identity_id"
        case encryptedContent = "encrypted_content"
        case type
        case createdAt
    }
    
    var createdDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt) ?? Date()
    }
}

struct Chat: Codable, Identifiable {
    let id: String
    let participants: [String]
    let isGroup: Bool
    let groupName: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case participants
        case isGroup = "is_group"
        case groupName = "group_name"
    }
}
