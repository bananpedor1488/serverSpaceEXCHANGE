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
    var isOnline: Bool = false
    var lastSeen: Int64 = 0
    
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
        isOnline = false
        lastSeen = 0
    }
    
    var lastMessageDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: lastMessageTime) ?? Date()
    }
    
    func formatLastSeen() -> String {
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
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let chatId: String
    let senderIdentityId: String
    let encryptedContent: String
    let type: String
    let createdAt: String
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
        delivered = (try? container.decode(Bool.self, forKey: .delivered)) ?? false
        deliveredAt = try? container.decode(String.self, forKey: .deliveredAt)
        read = (try? container.decode(Bool.self, forKey: .read)) ?? false
        readAt = try? container.decode(String.self, forKey: .readAt)
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
