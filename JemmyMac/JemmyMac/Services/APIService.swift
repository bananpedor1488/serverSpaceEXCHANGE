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
            
            if let urlString = json?["url"] as? String {
                print("✅ Link generated: \(urlString)")
                return urlString
            } else {
                print("❌ No url in response")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No url in response"])
            }
        } catch {
            print("❌ Generate link error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func useInviteLink(token: String) async throws -> Identity {
        print("📡 Request: GET /invite/preview/\(token)")
        
        let url = URL(string: "\(baseURL)/invite/preview/\(token)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Server error: \(errorText)")
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
                }
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let identityData = json?["identity"] as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: identityData) {
                let identity = try JSONDecoder().decode(Identity.self, from: jsonData)
                print("✅ Invite link preview loaded, identity: \(identity.username)")
                return identity
            }
            
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        } catch {
            print("❌ Use invite link error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func consumeInviteLink(token: String) async throws -> Identity {
        print("📡 Request: GET /invite/\(token) (CONSUME)")
        
        let url = URL(string: "\(baseURL)/invite/\(token)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Server error: \(errorText)")
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
                }
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let identityData = json?["identity"] as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: identityData) {
                let identity = try JSONDecoder().decode(Identity.self, from: jsonData)
                print("✅ Invite link consumed, identity: \(identity.username)")
                return identity
            }
            
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        } catch {
            print("❌ Consume invite link error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Chats
    
    func startChat(token: String, myIdentityId: String) async throws -> ChatStartResponse {
        print("📡 start chat:", token)
        
        let url = URL(string: "\(baseURL)/chat/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "token": token,
            "my_identity_id": myIdentityId
        ]
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
            
            let chatResponse = try JSONDecoder().decode(ChatStartResponse.self, from: data)
            print("✅ чат создан:", chatResponse.chatId)
            return chatResponse
        } catch {
            print("❌ error:", error.localizedDescription)
            throw error
        }
    }
    
    func getChats(identityId: String) async throws -> [ChatListItem] {
        print("📡 Request: GET /chats?identity_id=\(identityId)")
        
        let url = URL(string: "\(baseURL)/chats?identity_id=\(identityId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let chats = try JSONDecoder().decode([ChatListItem].self, from: data)
            print("📥 chats loaded:", chats.count)
            return chats
        } catch {
            print("❌ error:", error.localizedDescription)
            throw error
        }
    }
    
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
    
    func sendMessage(chatId: String, senderIdentityId: String, text: String) async throws -> ChatMessage {
        print("📤 message:", text)
        
        let url = URL(string: "\(baseURL)/message")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "chat_id": chatId,
            "sender_identity_id": senderIdentityId,
            "text": text
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let message = try JSONDecoder().decode(ChatMessage.self, from: data)
            print("✅ Message sent")
            return message
        } catch {
            print("❌ error:", error.localizedDescription)
            throw error
        }
    }
    
    func getMessages(chatId: String) async throws -> [ChatMessage] {
        print("📡 Request: GET /messages?chat_id=\(chatId)")
        
        let url = URL(string: "\(baseURL)/messages?chat_id=\(chatId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
            print("✅ Messages loaded:", messages.count)
            return messages
        } catch {
            print("❌ error:", error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Search
    
    func searchByTag(tag: String) async throws -> [Identity] {
        print("📡 Request: GET /identity/search?tag=\(tag)")
        
        let url = URL(string: "\(baseURL)/identity/search?tag=\(tag)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let identities = try JSONDecoder().decode([Identity].self, from: data)
            print("✅ Search results:", identities.count)
            return identities
        } catch {
            print("❌ Search error:", error.localizedDescription)
            throw error
        }
    }
}
