import Foundation

struct Identity: Codable, Identifiable {
    let id: String
    let username: String
    let avatar: String
    let bio: String
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case avatar
        case bio
        case expiresAt = "expires_at"
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
    let lastMessageTime: Date
    let user: Identity
    
    enum CodingKeys: String, CodingKey {
        case id
        case lastMessage
        case lastMessageTime
        case user
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let chatId: String
    let senderIdentityId: String
    let encryptedContent: String
    let type: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case chatId = "chat_id"
        case senderIdentityId = "sender_identity_id"
        case encryptedContent = "encrypted_content"
        case type
        case createdAt
    }
}
