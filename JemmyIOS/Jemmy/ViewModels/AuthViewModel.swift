import Foundation
import SwiftUI
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var identity: Identity?
    @Published var userId: String?
    @Published var deviceId: String
    @Published var ephemeralEnabled = false
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var existingAccount: Identity?
    @Published var accountError: String?
    
    private let identityKey = "cached_identity"
    private let userIdKey = "cached_user_id"
    private let deviceIdKey = "deviceId"
    private var periodicCheckTask: Task<Void, Never>?
    
    init() {
        print("🔧 AuthViewModel initialized")
        
        // Сначала пытаемся загрузить device_id из Keychain
        if let savedDeviceId = KeychainHelper.load(key: deviceIdKey) {
            self.deviceId = savedDeviceId
            print("📱 Device ID loaded from Keychain: \(savedDeviceId)")
        } else {
            // Если нет в Keychain, используем identifierForVendor или создаем новый
            if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
                self.deviceId = vendorId
                print("📱 Device ID from identifierForVendor: \(vendorId)")
            } else {
                // Если и identifierForVendor нет, создаем новый UUID
                self.deviceId = UUID().uuidString
                print("📱 New Device ID created: \(self.deviceId)")
            }
            
            // ВАЖНО: Сохраняем в Keychain чтобы он не менялся при переустановке
            KeychainHelper.save(key: deviceIdKey, value: self.deviceId)
            print("💾 Device ID saved to Keychain")
        }
        
        // Загружаем сохраненные данные
        loadCachedAuth()
    }
    
    private func loadCachedAuth() {
        if let savedUserId = UserDefaults.standard.string(forKey: userIdKey),
           let identityData = UserDefaults.standard.data(forKey: identityKey),
           let savedIdentity = try? JSONDecoder().decode(Identity.self, from: identityData) {
            self.userId = savedUserId
            self.identity = savedIdentity
            self.isAuthenticated = true
            print("📦 Loaded cached auth: \(savedIdentity.username)")
            
            // Connect WebSocket with cached credentials
            WebSocketManager.shared.connect(userId: savedUserId, identityId: savedIdentity.id)
            print("🔌 WebSocket connected with cached auth")
        }
    }
    
    private func saveAuth() {
        if let userId = userId {
            UserDefaults.standard.set(userId, forKey: userIdKey)
        }
        if let identity = identity,
           let identityData = try? JSONEncoder().encode(identity) {
            UserDefaults.standard.set(identityData, forKey: identityKey)
        }
        print("💾 Auth cached")
    }
    
    func register(isEphemeral: Bool = false) async {
        // Если уже есть сохраненные данные и нет интернета, используем их
        if isAuthenticated && !NetworkMonitor.shared.isConnected {
            print("📦 Using cached auth (offline mode)")
            return
        }
        
        print("🚀 Creating new account...")
        print("📱 Device ID: \(deviceId)")
        isLoading = true
        
        do {
            let publicKey = UUID().uuidString
            let response = try await APIService.shared.register(deviceId: deviceId, publicKey: publicKey)
            
            await MainActor.run {
                self.userId = response.userId
                self.identity = response.identity
                self.isAuthenticated = true
                saveAuth()
                
                print("✅ Registration complete")
                print("   User ID: \(response.userId)")
                print("   Username: \(response.identity.username)")
                print("   Device ID saved: \(self.deviceId)")
                
                if let userId = userId, let identityId = identity?.id {
                    WebSocketManager.shared.connect(userId: userId, identityId: identityId)
                }
                
                self.isLoading = false
            }
        } catch {
            print("❌ Registration failed: \(error.localizedDescription)")
            
            await MainActor.run {
                // Если есть кэш, используем его
                if isAuthenticated {
                    print("📦 Using cached auth after error")
                }
                self.isLoading = false
            }
        }
    }
    
    func checkDevice() async {
        print("🔍 Checking device...")
        print("📱 Device ID: \(deviceId)")
        
        do {
            let checkResponse = try await APIService.shared.checkDevice(deviceId: deviceId)
            
            print("📥 Check response: exists=\(checkResponse.exists)")
            if let identity = checkResponse.identity {
                print("   Found identity: \(identity.username)")
            }
            
            if checkResponse.exists, let existingIdentity = checkResponse.identity {
                print("✅ Found existing account: \(existingIdentity.username)")
                await MainActor.run {
                    self.existingAccount = existingIdentity
                }
            } else {
                print("ℹ️ No existing account found")
            }
        } catch {
            print("❌ Check device failed: \(error.localizedDescription)")
        }
    }
    
    func restoreAccount() async {
        print("🔄 Restoring account...")
        isLoading = true
        
        do {
            let checkResponse = try await APIService.shared.checkDevice(deviceId: deviceId)
            
            if checkResponse.exists, let existingIdentity = checkResponse.identity, let existingUserId = checkResponse.userId {
                await MainActor.run {
                    self.userId = existingUserId
                    self.identity = existingIdentity
                    self.isAuthenticated = true
                    self.existingAccount = nil
                    self.isLoading = false
                    saveAuth()
                    
                    print("✅ Account restored: \(existingIdentity.username)")
                    
                    if let userId = userId, let identityId = identity?.id {
                        WebSocketManager.shared.connect(userId: userId, identityId: identityId)
                    }
                }
            } else {
                print("❌ Account not found")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            print("❌ Restore failed: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func startPeriodicAccountCheck() {
        print("🔄 Starting periodic account check (every 3 seconds)")
        
        // Cancel existing task if any
        periodicCheckTask?.cancel()
        
        periodicCheckTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                
                if isAuthenticated, let identityId = identity?.id {
                    print("🔄 Periodic account check...")
                    await loadProfileSilently(identityId: identityId)
                }
            }
        }
    }
    
    func stopPeriodicAccountCheck() {
        print("⏹️ Stopping periodic account check")
        periodicCheckTask?.cancel()
        periodicCheckTask = nil
    }
    
    private func loadProfileSilently(identityId: String) async {
        do {
            let updatedIdentity = try await APIService.shared.getProfile(identityId: identityId)
            self.identity = updatedIdentity
            saveAuth()
        } catch let error as NSError {
            // Check if identity not found - account was deleted
            if error.code == 404 || error.localizedDescription.lowercased().contains("identity not found") {
                print("🚨 ПОДОЗРЕНИЕ: Незарегистрированный аккаунт - выполняем выход")
                
                // Clear data
                KeychainHelper.delete(key: deviceIdKey)
                UserDefaults.standard.removeObject(forKey: userIdKey)
                UserDefaults.standard.removeObject(forKey: identityKey)
                
                // Show error alert
                self.accountError = "⚠️ ПОДОЗРЕНИЕ\n\nНезарегистрированный аккаунт. Аккаунт был удален или не существует.\n\nВыполняем выход."
                self.isAuthenticated = false
                self.identity = nil
            }
        }
    }
    
    func loadProfile() async {
        guard let identityId = identity?.id else {
            print("⚠️ Cannot load profile: no identity ID")
            return
        }
        
        print("📡 Loading profile...")
        
        do {
            let updatedIdentity = try await APIService.shared.getProfile(identityId: identityId)
            self.identity = updatedIdentity
            saveAuth()
            print("✅ Profile loaded successfully")
        } catch let error as NSError {
            print("❌ Failed to load profile: \(error.localizedDescription)")
            
            // Check if identity not found - account was deleted
            if error.code == 404 || error.localizedDescription.lowercased().contains("identity not found") {
                print("🚨 ПОДОЗРЕНИЕ: Незарегистрированный аккаунт - выполняем выход")
                
                // Clear data
                KeychainHelper.delete(key: deviceIdKey)
                UserDefaults.standard.removeObject(forKey: userIdKey)
                UserDefaults.standard.removeObject(forKey: identityKey)
                
                // Show error alert
                self.accountError = "⚠️ ПОДОЗРЕНИЕ\n\nНезарегистрированный аккаунт. Аккаунт был удален или не существует.\n\nВыполняем выход."
                self.isAuthenticated = false
                self.identity = nil
            }
        }
    }
    
    func dismissError() {
        print("Dismissing error")
        accountError = nil
    }
    
    func updateProfile(username: String?, bio: String?, avatar: String? = nil) async throws {
        guard let identityId = identity?.id else {
            print("⚠️ Cannot update profile: no identity ID")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No identity ID"])
        }
        
        print("📡 Updating profile...")
        if avatar != nil {
            print("   Avatar: Yes (base64 length: \(avatar!.count))")
        }
        
        do {
            let updatedIdentity = try await APIService.shared.updateProfile(
                identityId: identityId,
                username: username,
                bio: bio,
                avatar: avatar
            )
            
            self.identity = updatedIdentity
            saveAuth()
            
            // Save avatar to cache if updated
            if !updatedIdentity.avatar.isEmpty, let avatarUpdatedAt = updatedIdentity.avatarUpdatedAt {
                CacheManager.shared.saveAvatar(userId: identityId, base64: updatedIdentity.avatar, updatedAt: avatarUpdatedAt)
                print("💾 Avatar saved to cache")
            }
            
            print("✅ Profile updated in ViewModel")
        } catch {
            print("❌ Failed to update profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    func toggleEphemeral() async {
        print("🔄 Toggling ephemeral mode...")
        
        do {
            ephemeralEnabled.toggle()
            try await APIService.shared.toggleEphemeral(deviceId: deviceId, enabled: ephemeralEnabled)
            print("✅ Ephemeral mode: \(ephemeralEnabled ? "ON" : "OFF")")
        } catch {
            print("❌ Failed to toggle ephemeral: \(error.localizedDescription)")
            ephemeralEnabled.toggle()
        }
    }
    
    func deleteAccount() async throws {
        print("⚠️ Deleting account...")
        
        do {
            try await APIService.shared.deleteAccount(deviceId: deviceId)
            
            // Clear local data
            KeychainHelper.delete(key: deviceIdKey)
            UserDefaults.standard.removeObject(forKey: userIdKey)
            UserDefaults.standard.removeObject(forKey: identityKey)
            UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
            
            self.identity = nil
            self.isAuthenticated = false
            
            print("✅ Account deleted successfully")
        } catch {
            print("❌ Failed to delete account: \(error.localizedDescription)")
            throw error
        }
    }
    
    func logout() {
        print("👋 Logging out...")
        
        KeychainHelper.delete(key: deviceIdKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: identityKey)
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        
        self.identity = nil
        self.isAuthenticated = false
        
        print("✅ Logged out successfully")
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
