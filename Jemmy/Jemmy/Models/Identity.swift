import Foundation

struct Identity: Codable, Identifiable {
    let id: String
    let username: String
    let tag: String
    let avatarSeed: String
    let bio: String
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case tag
        case avatarSeed = "avatar_seed"
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
