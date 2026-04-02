import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://weeky-six.vercel.app/api"
    
    private init() {}
    
    // MARK: - Auth
    
    func register(deviceId: String, publicKey: String) async throws -> AuthResponse {
        print("📡 Request: POST /auth/register")
        print("📦 Body: device_id=\(deviceId)")
        
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["device_id": deviceId, "public_key": publicKey]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            print("✅ Registration successful: \(authResponse.identity.username)")
            return authResponse
        } catch {
            print("❌ Registration error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func toggleEphemeral(deviceId: String, enabled: Bool) async throws {
        print("📡 Request: POST /auth/toggle-ephemeral")
        print("📦 Body: device_id=\(deviceId), enabled=\(enabled)")
        
        let url = URL(string: "\(baseURL)/auth/toggle-ephemeral")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["device_id": deviceId, "enabled": enabled]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
                print("✅ Ephemeral toggled successfully")
            }
        } catch {
            print("❌ Toggle ephemeral error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Profile
    
    func getProfile(identityId: String) async throws -> Identity {
        print("📡 Request: GET /identity/\(identityId)")
        
        let url = URL(string: "\(baseURL)/identity/\(identityId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let identity = try JSONDecoder().decode(Identity.self, from: data)
            print("✅ Profile loaded: \(identity.username)")
            return identity
        } catch {
            print("❌ Get profile error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateProfile(identityId: String, username: String?, tag: String?, bio: String?, avatarSeed: String?) async throws -> Identity {
        print("📡 Request: POST /identity/update")
        print("📦 Body: identity_id=\(identityId)")
        if let username = username { print("   username=\(username)") }
        if let tag = tag { print("   tag=\(tag)") }
        if let bio = bio { print("   bio=\(bio)") }
        
        let url = URL(string: "\(baseURL)/identity/update")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["identity_id": identityId]
        if let username = username { body["username"] = username }
        if let tag = tag { body["tag"] = tag }
        if let bio = bio { body["bio"] = bio }
        if let avatarSeed = avatarSeed { body["avatar_seed"] = avatarSeed }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Server error: \(errorText)")
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
                }
            }
            
            let identity = try JSONDecoder().decode(Identity.self, from: data)
            print("✅ Profile updated: \(identity.username)")
            return identity
        } catch {
            print("❌ Update profile error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteAccount(deviceId: String) async throws {
        print("📡 Request: DELETE /account")
        print("📦 Body: device_id=\(deviceId)")
        
        let url = URL(string: "\(baseURL)/account/delete")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["device_id": deviceId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
                print("✅ Account deleted successfully")
            }
        } catch {
            print("❌ Delete account error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Invite Links
    
    func generateInviteLink(identityId: String) async throws -> String {
        print("📡 Request: POST /identity/generate-link")
        print("📦 Body: identity_id=\(identityId)")
        
        let url = URL(string: "\(baseURL)/identity/generate-link")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["identity_id": identityId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let link = json?["link"] as? String {
                print("✅ Link generated: \(link)")
                return link
            } else {
                print("❌ No link in response")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No link in response"])
            }
        } catch {
            print("❌ Generate link error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Search
    
    func searchByTag(tag: String) async throws -> Identity {
        print("📡 Request: GET /identity/search/\(tag)")
        
        let url = URL(string: "\(baseURL)/identity/search/\(tag)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 404 {
                    print("❌ Identity not found")
                    throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Identity not found"])
                }
            }
            
            let identity = try JSONDecoder().decode(Identity.self, from: data)
            print("✅ Identity found: \(identity.username)")
            return identity
        } catch {
            print("❌ Search error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Chats
    
    func getUserChats(identityId: String) async throws -> [Chat] {
        print("📡 Request: GET /chat/user/\(identityId)")
        
        let url = URL(string: "\(baseURL)/chat/user/\(identityId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let chats = try JSONDecoder().decode([Chat].self, from: data)
            print("✅ Chats loaded: \(chats.count) chats")
            return chats
        } catch {
            print("❌ Get chats error: \(error.localizedDescription)")
            throw error
        }
    }
}
