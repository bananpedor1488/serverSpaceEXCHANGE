import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var identity: Identity?
    @Published var userId: String?
    @Published var deviceId: String
    @Published var isAuthenticated = false
    @Published var chats: [Chat] = []
    
    private let deviceIdKey = "deviceId"
    
    init() {
        // Пытаемся загрузить deviceId из Keychain (сохраняется даже после удаления приложения)
        if let savedDeviceId = KeychainHelper.load(key: deviceIdKey) {
            self.deviceId = savedDeviceId
            print("📱 Device ID loaded from Keychain: \(savedDeviceId)")
        } else {
            // Если нет в Keychain, создаем новый и сохраняем
            self.deviceId = UUID().uuidString
            KeychainHelper.save(key: deviceIdKey, value: self.deviceId)
            print("📱 New Device ID created and saved to Keychain: \(self.deviceId)")
        }
    }
    
    func register() async {
        print("🚀 Starting registration...")
        
        do {
            let publicKey = UUID().uuidString
            let response = try await APIService.shared.register(deviceId: deviceId, publicKey: publicKey)
            
            self.userId = response.userId
            self.identity = response.identity
            self.isAuthenticated = true
            
            print("✅ Registration complete")
            print("   User ID: \(response.userId)")
            print("   Username: \(response.identity.username)")
            
            await loadChats()
        } catch {
            print("❌ Registration failed: \(error.localizedDescription)")
        }
    }
    
    func loadChats() async {
        guard let identityId = identity?.id else { return }
        
        print("📡 Loading chats...")
        
        do {
            let loadedChats = try await APIService.shared.getUserChats(identityId: identityId)
            self.chats = loadedChats
            print("✅ Chats loaded: \(loadedChats.count)")
        } catch {
            print("❌ Failed to load chats: \(error.localizedDescription)")
        }
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    static func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Удаляем старое значение если есть
        SecItemDelete(query as CFDictionary)
        
        // Добавляем новое
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Saved to Keychain: \(key)")
        } else {
            print("❌ Failed to save to Keychain: \(status)")
        }
    }
    
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            print("✅ Loaded from Keychain: \(key)")
            return value
        } else {
            print("⚠️ Not found in Keychain: \(key)")
            return nil
        }
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("✅ Deleted from Keychain: \(key)")
        } else {
            print("⚠️ Failed to delete from Keychain: \(status)")
        }
    }
}
