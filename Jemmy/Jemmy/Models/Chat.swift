import Foundation

struct Chat: Codable, Identifiable {
    let id: String
    let participants: [Identity]
    let isGroup: Bool
    let groupName: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case participants
        case isGroup = "is_group"
        case groupName = "group_name"
    }
}

struct Message: Codable, Identifiable {
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
