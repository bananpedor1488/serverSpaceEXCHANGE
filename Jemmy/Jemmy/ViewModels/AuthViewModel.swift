import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var identity: Identity?
    @Published var userId: String?
    @Published var deviceId: String
    @Published var ephemeralEnabled = false
    @Published var isLoading = false
    
    init() {
        if let savedDeviceId = UserDefaults.standard.string(forKey: "deviceId") {
            self.deviceId = savedDeviceId
        } else {
            self.deviceId = UUID().uuidString
            UserDefaults.standard.set(self.deviceId, forKey: "deviceId")
        }
    }
    
    func register() async {
        isLoading = true
        do {
            let publicKey = UUID().uuidString
            let response = try await APIService.shared.register(deviceId: deviceId, publicKey: publicKey)
            self.userId = response.userId
            self.identity = response.identity
            
            if let userId = userId {
                SocketService.shared.connect(userId: userId)
            }
        } catch {
            print("Registration error: \(error)")
        }
        isLoading = false
    }
    
    func toggleEphemeral() async {
        do {
            ephemeralEnabled.toggle()
            try await APIService.shared.toggleEphemeral(deviceId: deviceId, enabled: ephemeralEnabled)
        } catch {
            print("Toggle ephemeral error: \(error)")
            ephemeralEnabled.toggle()
        }
    }
}
