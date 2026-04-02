import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://weeky-six.vercel.app/api"
    
    private init() {}
    
    func register(deviceId: String, publicKey: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["device_id": deviceId, "public_key": publicKey]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func toggleEphemeral(deviceId: String, enabled: Bool) async throws {
        let url = URL(string: "\(baseURL)/auth/toggle-ephemeral")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["device_id": deviceId, "enabled": enabled]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        _ = try await URLSession.shared.data(for: request)
    }
    
    func getUserChats(identityId: String) async throws -> [Chat] {
        let url = URL(string: "\(baseURL)/chat/user/\(identityId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Chat].self, from: data)
    }
}
