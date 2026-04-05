import Foundation

class APIService {
    static let shared = APIService()
    let baseURL = "https://weeky-six.vercel.app/api"
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
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
    
    func checkDevice(deviceId: String) async throws -> DeviceCheckResponse {
        print("📡 Request: GET /auth/check-device/\(deviceId)")
        
        let url = URL(string: "\(baseURL)/auth/check-device/\(deviceId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let checkResponse = try JSONDecoder().decode(DeviceCheckResponse.self, from: data)
            print("✅ Device check: exists=\(checkResponse.exists)")
            return checkResponse
        } catch {
            print("❌ Device check error: \(error.localizedDescription)")
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
    
    // MARK: - Username
    
    func checkUsername(username: String) async throws -> Bool {
        print("📡 Request: GET /identity/check-username/\(username)")
        
        let url = URL(string: "\(baseURL)/identity/check-username/\(username)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let available = json?["available"] as? Bool {
                print(available ? "✅ Username available" : "❌ Username taken")
                return available
            }
            
            return false
        } catch {
            print("❌ Check username error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func isValidUsername(_ username: String) -> Bool {
        let regex = "^[a-zA-Z0-9_]{4,16}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: username)
    }
    
    func getProfile(identityId: String) async throws -> Identity {
        print("📡 Request: GET /identity/\(identityId)")
        
        let url = URL(string: "\(baseURL)/identity/\(identityId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 404 {
                    print("❌ Identity not found (404)")
                    throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Identity not found"])
                }
                
                if httpResponse.statusCode != 200 {
                    let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Server error: \(errorText)")
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
                }
            }
            
            let identity = try JSONDecoder().decode(Identity.self, from: data)
            print("✅ Profile loaded: \(identity.username)")
            return identity
        } catch {
            print("❌ Get profile error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateProfile(identityId: String, username: String?, bio: String?, avatar: String? = nil) async throws -> Identity {
        print("📡 Request: POST /identity/update")
        print("📦 Body: identity_id=\(identityId)")
        if let username = username { print("   username=\(username)") }
        if let bio = bio { print("   bio=\(bio)") }
        if let avatar = avatar { print("   avatar: Yes (length: \(avatar.count))") }
        
        let url = URL(string: "\(baseURL)/identity/update")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["identity_id": identityId]
        if let username = username { body["username"] = username }
        if let bio = bio { body["bio"] = bio }
        if let avatar = avatar { body["avatar"] = avatar }
        
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
    
    func uploadAvatar(identityId: String, base64: String) async throws -> Identity {
        print("📡 Request: POST /identity/upload-avatar")
        print("📦 Identity ID: \(identityId)")
        print("📦 Avatar size: \(base64.count) chars")
        
        let url = URL(string: "\(baseURL)/identity/upload-avatar")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "identity_id": identityId,
            "avatar": base64
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let identityData = json?["identity"] as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: identityData) {
                let identity = try JSONDecoder().decode(Identity.self, from: jsonData)
                print("✅ Avatar uploaded")
                return identity
            }
            
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        } catch {
            print("❌ Upload avatar error: \(error.localizedDescription)")
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
    
    func startDirectChat(myIdentityId: String, otherIdentityId: String) async throws -> ChatStartResponse {
        print("📡 start direct chat")
        
        let url = URL(string: "\(baseURL)/chat/direct")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "my_identity_id": myIdentityId,
            "other_identity_id": otherIdentityId
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
    
    func sendMessage(chatId: String, senderIdentityId: String, text: String) async throws -> ChatMessage {
        print("📤 message:", text)
        
        let url = URL(string: "\(baseURL)/message")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let clientTime = Int64(Date().timeIntervalSince1970 * 1000)
        
        let body: [String: Any] = [
            "chat_id": chatId,
            "sender_identity_id": senderIdentityId,
            "text": text,
            "client_time": clientTime
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
            
            // Настраиваем декодер для правильного парсинга дат
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let messages = try decoder.decode([ChatMessage].self, from: data)
            print("✅ Messages loaded:", messages.count)
            if let first = messages.first {
                print("   First message createdAt: \(first.createdAt)")
            }
            return messages
        } catch {
            print("❌ error:", error.localizedDescription)
            throw error
        }
    }
    
    func deleteChat(chatId: String) async throws {
        let url = URL(string: "\(baseURL)/api/chat/\(chatId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        print("📡 Request: DELETE \(url.absoluteString)")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("✅ Chat deleted successfully")
                } else {
                    print("❌ Failed to delete chat: \(httpResponse.statusCode)")
                    throw NSError(domain: "DeleteChat", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to delete chat"])
                }
            }
        } catch {
            print("❌ Delete chat error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getUserStatus(identityId: String) async throws -> (online: Bool, lastSeen: Int64) {
        print("📡 Request: GET /user/status/\(identityId)")
        
        let url = URL(string: "\(baseURL)/api/user/status/\(identityId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let online = json?["online"] as? Bool ?? false
            let lastSeen = json?["last_seen"] as? Int64 ?? 0
            
            print("✅ Status loaded: online=\(online), lastSeen=\(lastSeen)")
            return (online, lastSeen)
        } catch {
            print("❌ error:", error.localizedDescription)
            throw error
        }
    }
    
    func toggleChatPin(chatId: String, identityId: String, isPinned: Bool) async throws -> Bool {
        print("📡 Request: POST /chats/\(chatId)/pin")
        
        let url = URL(string: "\(baseURL)/chats/\(chatId)/pin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct PinRequest: Encodable {
            let identity_id: String
            let is_pinned: Bool
        }
        
        let body = PinRequest(identity_id: identityId, is_pinned: !isPinned)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([String: Bool].self, from: data)
        return response["is_pinned"] ?? false
    }
    
    func toggleChatMute(chatId: String, identityId: String, isMuted: Bool) async throws -> Bool {
        print("📡 Request: POST /chats/\(chatId)/mute")
        
        let url = URL(string: "\(baseURL)/chats/\(chatId)/mute")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct MuteRequest: Encodable {
            let identity_id: String
            let is_muted: Bool
        }
        
        let body = MuteRequest(identity_id: identityId, is_muted: !isMuted)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([String: Bool].self, from: data)
        return response["is_muted"] ?? false
    }
    
    func markChatAsRead(chatId: String, identityId: String) async throws {
        print("📡 Request: PATCH /chat/\(chatId)/read")
        
        let url = URL(string: "\(baseURL)/chat/\(chatId)/read")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["identity_id": identityId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
        print("✅ Chat marked as read")
    }
    
    // MARK: - Privacy Settings
    
    func updatePrivacySettings(identityId: String, settings: PrivacySettings) async throws -> PrivacySettings {
        print("📡 Request: PATCH /identity/privacy/update")
        
        let url = URL(string: "\(baseURL)/identity/privacy/update")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "identity_id": identityId,
            "settings": [
                "who_can_message": settings.whoCanMessage.rawValue,
                "who_can_see_profile": settings.whoCanSeeProfile.rawValue,
                "who_can_see_online": settings.whoCanSeeOnline.rawValue,
                "who_can_see_last_seen": settings.whoCanSeeLastSeen.rawValue,
                "auto_delete_messages": settings.autoDeleteMessages,
                "screenshot_protection": settings.screenshotProtection
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Сервер возвращает { success: true, privacy_settings: {...} }
        struct Response: Codable {
            let success: Bool?
            let privacy_settings: PrivacySettings
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        
        print("✅ Privacy settings updated: screenshot_protection = \(response.privacy_settings.screenshotProtection)")
        return response.privacy_settings
    }
    
    func getPrivacySettings(identityId: String) async throws -> PrivacySettings {
        print("📡 Request: GET /identity/privacy/\(identityId)")
        
        let url = URL(string: "\(baseURL)/identity/privacy/\(identityId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode([String: PrivacySettings].self, from: data)
        print("✅ Privacy settings loaded")
        return response["privacy_settings"] ?? .default
    }
    
    func blockUser(blockerIdentityId: String, blockedIdentityId: String) async throws {
        print("📡 Request: POST /identity/block")
        
        let url = URL(string: "\(baseURL)/identity/block")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "blocker_identity_id": blockerIdentityId,
            "blocked_identity_id": blockedIdentityId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
        print("✅ User blocked")
    }
    
    func unblockUser(blockerIdentityId: String, blockedIdentityId: String) async throws {
        print("📡 Request: POST /identity/unblock")
        
        let url = URL(string: "\(baseURL)/identity/unblock")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "blocker_identity_id": blockerIdentityId,
            "blocked_identity_id": blockedIdentityId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
        print("✅ User unblocked")
    }
    
    func getBlockedUsers(identityId: String) async throws -> [Identity] {
        print("📡 Request: GET /identity/blocked-list/\(identityId)")
        
        let url = URL(string: "\(baseURL)/identity/blocked-list/\(identityId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response: \(httpResponse.statusCode)")
            }
            
            // Log raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 Raw response: \(jsonString)")
            }
            
            // Try to decode the response
            let decoder = JSONDecoder()
            let blockedResponse = try decoder.decode(BlockedUserResponse.self, from: data)
            print("✅ Blocked users loaded: \(blockedResponse.blockedUsers.count)")
            return blockedResponse.blockedUsers
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ Key '\(key.stringValue)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
            
            // Try to parse as raw JSON to see what we got
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("📦 Actual JSON structure:", json)
            }
            
            throw DecodingError.keyNotFound(key, context)
        } catch {
            print("❌ Failed to decode blocked users: \(error)")
            throw error
        }
    }
}
