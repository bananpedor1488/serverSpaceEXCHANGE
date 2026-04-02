import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var identity: Identity?
    @Published var userId: String?
    @Published var deviceId: String
    @Published var ephemeralEnabled = false
    @Published var isLoading = false
    @Published var isAuthenticated = false
    
    init() {
        print("🔧 AuthViewModel initialized")
        if let savedDeviceId = UserDefaults.standard.string(forKey: "deviceId") {
            self.deviceId = savedDeviceId
            print("📱 Device ID loaded: \(savedDeviceId)")
        } else {
            self.deviceId = UUID().uuidString
            UserDefaults.standard.set(self.deviceId, forKey: "deviceId")
            print("📱 New Device ID created: \(self.deviceId)")
        }
    }
    
    func register() async {
        print("🚀 Starting registration...")
        isLoading = true
        
        do {
            let publicKey = UUID().uuidString
            let response = try await APIService.shared.register(deviceId: deviceId, publicKey: publicKey)
            
            self.userId = response.userId
            self.identity = response.identity
            self.isAuthenticated = true
            
            print("✅ Registration complete")
            print("   User ID: \(response.userId)")
            print("   Username: \(response.identity.username)")
            print("   Tag: \(response.identity.tag)")
            
            if let userId = userId {
                SocketService.shared.connect(userId: userId)
            }
        } catch {
            print("❌ Registration failed: \(error.localizedDescription)")
        }
        
        isLoading = false
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
            print("✅ Profile loaded successfully")
        } catch {
            print("❌ Failed to load profile: \(error.localizedDescription)")
        }
    }
    
    func updateProfile(username: String?, bio: String?) async throws {
        guard let identityId = identity?.id else {
            print("⚠️ Cannot update profile: no identity ID")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No identity ID"])
        }
        
        print("📡 Updating profile...")
        
        do {
            let updatedIdentity = try await APIService.shared.updateProfile(
                identityId: identityId,
                username: username,
                bio: bio
            )
            
            self.identity = updatedIdentity
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
            UserDefaults.standard.removeObject(forKey: "device_id")
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
        
        UserDefaults.standard.removeObject(forKey: "device_id")
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        
        self.identity = nil
        self.isAuthenticated = false
        
        print("✅ Logged out successfully")
    }
}
