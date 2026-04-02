import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://weeky-six.vercel.app/api"
    
    private init() {}
    
    func register(deviceId: String, publicKey: String) async throws -> AuthResponse {
        print("📡 Request: POST /auth/register")
        
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["device_id": deviceId, "public_key": publicKey]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        print("✅ Registration successful: \(authResponse.identity.username)")
        return authResponse
    }
    
    func generateInviteLink(identityId: String) async throws -> String {
        print("📡 Request: POST /identity/generate-link")
        
        let url = URL(string: "\(baseURL)/identity/generate-link")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["identity_id": identityId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let urlString = json?["url"] as? String {
            print("✅ Link generated: \(urlString)")
            return urlString
        }
        
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No url in response"])
    }
    
    func useInviteLink(token: String) async throws -> Identity {
        print("📡 Request: GET /invite/\(token)")
        
        let url = URL(string: "\(baseURL)/invite/\(token)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let identityData = json?["identity"] as? [String: Any],
           let jsonData = try? JSONSerialization.data(withJSONObject: identityData) {
            let identity = try JSONDecoder().decode(Identity.self, from: jsonData)
            print("✅ Invite link used, identity: \(identity.username)")
            return identity
        }
        
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
    }
    
    func getUserChats(identityId: String) async throws -> [Chat] {
        print("📡 Request: GET /chat/user/\(identityId)")
        
        let url = URL(string: "\(baseURL)/chat/user/\(identityId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let chats = try JSONDecoder().decode([Chat].self, from: data)
        print("✅ Chats loaded: \(chats.count) chats")
        return chats
    }
    
    func createChat(identityIds: [String]) async throws -> Chat {
        print("📡 Request: POST /chat/create")
        
        let url = URL(string: "\(baseURL)/chat/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "identity_ids": identityIds,
            "is_group": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let chat = try JSONDecoder().decode(Chat.self, from: data)
        print("✅ Chat created")
        return chat
    }
}
