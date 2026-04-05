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
        case _id = "_id"
        case id
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
        
        // Try _id first, then id
        if let _id = try? container.decode(String.self, forKey: ._id) {
            id = _id
        } else if let idValue = try? container.decode(String.self, forKey: .id) {
            id = idValue
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys._id,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Neither '_id' nor 'id' found"
                )
            )
        }
        
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
        try container.encode(id, forKey: ._id)
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

struct DeviceCheckResponse: Codable {
    let exists: Bool
    let identity: Identity?
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case exists
        case identity
        case userId = "user_id"
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
    var isOnline: Bool? = nil
    var lastSeen: Int64? = nil
    
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
        isOnline = nil
        lastSeen = nil
    }
    
    var lastMessageDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: lastMessageTime) ?? Date()
    }
    
    func formatLastSeen() -> String {
        if isOnline == true {
            return "в сети"
        } else if let lastSeen = lastSeen, lastSeen > 0 {
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
            return "" // Не показываем статус пока не загрузился
        }
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let chatId: String
    let senderIdentityId: String
    let encryptedContent: String
    let type: String
    let createdAt: String
    let clientTime: Int64?
    let serverTime: Int64?
    let delivered: Bool
    let deliveredAt: String?
    let read: Bool
    let readAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case chatId = "chat_id"
        case senderIdentityId = "sender_identity_id"
        case encryptedContent = "encrypted_content"
        case type
        case createdAt
        case clientTime = "client_time"
        case serverTime = "server_time"
        case delivered
        case deliveredAt = "delivered_at"
        case read
        case readAt = "read_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        chatId = try container.decode(String.self, forKey: .chatId)
        senderIdentityId = try container.decode(String.self, forKey: .senderIdentityId)
        encryptedContent = try container.decode(String.self, forKey: .encryptedContent)
        type = try container.decode(String.self, forKey: .type)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        clientTime = try? container.decode(Int64.self, forKey: .clientTime)
        serverTime = try? container.decode(Int64.self, forKey: .serverTime)
        delivered = (try? container.decode(Bool.self, forKey: .delivered)) ?? false
        deliveredAt = try? container.decode(String.self, forKey: .deliveredAt)
        read = (try? container.decode(Bool.self, forKey: .read)) ?? false
        readAt = try? container.decode(String.self, forKey: .readAt)
    }
    
    var createdDate: Date {
        // Используем serverTime если есть, иначе clientTime, иначе парсим createdAt
        if let serverTime = serverTime {
            return Date(timeIntervalSince1970: TimeInterval(serverTime) / 1000)
        } else if let clientTime = clientTime {
            return Date(timeIntervalSince1970: TimeInterval(clientTime) / 1000)
        } else {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: createdAt) ?? Date()
        }
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

// MARK: - Privacy Settings

struct PrivacySettings: Codable {
    var whoCanMessage: PrivacyOption
    var whoCanSeeProfile: PrivacyOption
    var whoCanSeeOnline: PrivacyOption
    var whoCanSeeLastSeen: PrivacyOption
    var autoDeleteMessages: Int // hours: 0, 24, 168, 720
    var screenshotProtection: Bool
    
    enum CodingKeys: String, CodingKey {
        case whoCanMessage = "who_can_message"
        case whoCanSeeProfile = "who_can_see_profile"
        case whoCanSeeOnline = "who_can_see_online"
        case whoCanSeeLastSeen = "who_can_see_last_seen"
        case autoDeleteMessages = "auto_delete_messages"
        case screenshotProtection = "screenshot_protection"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        whoCanMessage = try container.decode(PrivacyOption.self, forKey: .whoCanMessage)
        whoCanSeeProfile = try container.decode(PrivacyOption.self, forKey: .whoCanSeeProfile)
        whoCanSeeOnline = try container.decode(PrivacyOption.self, forKey: .whoCanSeeOnline)
        whoCanSeeLastSeen = try container.decode(PrivacyOption.self, forKey: .whoCanSeeLastSeen)
        autoDeleteMessages = try container.decode(Int.self, forKey: .autoDeleteMessages)
        // Дефолтное значение false если поле отсутствует
        screenshotProtection = (try? container.decode(Bool.self, forKey: .screenshotProtection)) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(whoCanMessage, forKey: .whoCanMessage)
        try container.encode(whoCanSeeProfile, forKey: .whoCanSeeProfile)
        try container.encode(whoCanSeeOnline, forKey: .whoCanSeeOnline)
        try container.encode(whoCanSeeLastSeen, forKey: .whoCanSeeLastSeen)
        try container.encode(autoDeleteMessages, forKey: .autoDeleteMessages)
        try container.encode(screenshotProtection, forKey: .screenshotProtection)
    }
    
    static var `default`: PrivacySettings {
        PrivacySettings(
            whoCanMessage: .everyone,
            whoCanSeeProfile: .everyone,
            whoCanSeeOnline: .everyone,
            whoCanSeeLastSeen: .everyone,
            autoDeleteMessages: 0,
            screenshotProtection: false
        )
    }
    
    init(whoCanMessage: PrivacyOption, whoCanSeeProfile: PrivacyOption, whoCanSeeOnline: PrivacyOption, whoCanSeeLastSeen: PrivacyOption, autoDeleteMessages: Int, screenshotProtection: Bool) {
        self.whoCanMessage = whoCanMessage
        self.whoCanSeeProfile = whoCanSeeProfile
        self.whoCanSeeOnline = whoCanSeeOnline
        self.whoCanSeeLastSeen = whoCanSeeLastSeen
        self.autoDeleteMessages = autoDeleteMessages
        self.screenshotProtection = screenshotProtection
    }
}

enum PrivacyOption: String, Codable, CaseIterable {
    case everyone = "everyone"
    case contacts = "contacts"
    case nobody = "nobody"
    
    var displayName: String {
        switch self {
        case .everyone: return "Все"
        case .contacts: return "Контакты"
        case .nobody: return "Никто"
        }
    }
}

struct BlockedUserResponse: Codable {
    let blockedUsers: [Identity]
    
    enum CodingKeys: String, CodingKey {
        case blockedUsers = "blocked_users"
    }
}
