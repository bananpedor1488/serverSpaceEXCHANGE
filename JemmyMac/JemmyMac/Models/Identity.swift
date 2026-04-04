import Foundation

struct Identity: Codable, Identifiable {
    let id: String
    let username: String
    let avatar: String
    let avatarUpdatedAt: Int64?
    let bio: String
    let expiresAt: Date?
    let isOnline: Bool?
    let lastSeen: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case avatar
        case avatarUpdatedAt = "avatar_updated_at"
        case bio
        case expiresAt = "expires_at"
        case isOnline = "is_online"
        case lastSeen = "last_seen"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        avatar = (try? container.decode(String.self, forKey: .avatar)) ?? ""
        bio = (try? container.decode(String.self, forKey: .bio)) ?? ""
        expiresAt = try? container.decode(Date.self, forKey: .expiresAt)
        isOnline = try? container.decode(Bool.self, forKey: .isOnline)
        lastSeen = try? container.decode(String.self, forKey: .lastSeen)
        
        // Parse avatarUpdatedAt - может быть ISO строка или Long
        if let timestampString = try? container.decode(String.self, forKey: .avatarUpdatedAt) {
            // Если строка - пытаемся распарсить как ISO дату
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: timestampString) {
                avatarUpdatedAt = Int64(date.timeIntervalSince1970 * 1000)
            } else {
                avatarUpdatedAt = nil
            }
        } else if let timestamp = try? container.decode(Int64.self, forKey: .avatarUpdatedAt) {
            // Если число - используем как есть
            avatarUpdatedAt = timestamp
        } else {
            avatarUpdatedAt = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(avatar, forKey: .avatar)
        try container.encodeIfPresent(avatarUpdatedAt, forKey: .avatarUpdatedAt)
        try container.encode(bio, forKey: .bio)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(isOnline, forKey: .isOnline)
        try container.encodeIfPresent(lastSeen, forKey: .lastSeen)
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case lastMessage
        case lastMessageTime
        case user
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
