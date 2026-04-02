import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var identity: Identity?
    @Published var userId: String?
    @Published var deviceId: String
    @Published var isAuthenticated = false
    @Published var chats: [Chat] = []
    
    init() {
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
