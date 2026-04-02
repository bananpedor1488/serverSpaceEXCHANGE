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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar) ?? ""
        bio = try container.decodeIfPresent(String.self, forKey: .bio) ?? ""
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
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
