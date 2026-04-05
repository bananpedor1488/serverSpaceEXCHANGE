import Foundation

@MainActor
class PrivacyViewModel: ObservableObject {
    @Published var settings: PrivacySettings = .default
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadSettings(identityId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedSettings = try await APIService.shared.getPrivacySettings(identityId: identityId)
            self.settings = loadedSettings
            print("✅ Privacy settings loaded")
        } catch {
            print("❌ Failed to load privacy settings: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            // Use default settings on error
            self.settings = .default
        }
        
        isLoading = false
    }
    
    func saveSettings(identityId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedSettings = try await APIService.shared.updatePrivacySettings(
                identityId: identityId,
                settings: settings
            )
            self.settings = updatedSettings
            print("✅ Privacy settings saved")
        } catch {
            print("❌ Failed to save privacy settings: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateOption(_ keyPath: WritableKeyPath<PrivacySettings, PrivacyOption>, value: PrivacyOption, identityId: String) {
        settings[keyPath: keyPath] = value
        
        Task {
            await saveSettings(identityId: identityId)
        }
    }
    
    func updateAutoDelete(_ hours: Int, identityId: String) {
        settings.autoDeleteMessages = hours
        
        Task {
            await saveSettings(identityId: identityId)
        }
    }
}
