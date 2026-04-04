import Foundation
import LocalAuthentication
import Security

class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    @Published var isAppLocked = false
    @Published var requiresAuthentication = false
    
    private let keychainService = "com.jemmy.app"
    private let pinKey = "app_pin_code"
    private let biometricEnabledKey = "biometric_enabled"
    private let autoLockKey = "auto_lock_minutes"
    private let hideNotificationContentKey = "hide_notification_content"
    private let screenshotProtectionKey = "screenshot_protection"
    
    private init() {
        loadSettings()
    }
    
    // MARK: - PIN Code
    
    var hasPinCode: Bool {
        return getPinCode() != nil
    }
    
    func setPinCode(_ pin: String) -> Bool {
        let data = pin.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: pinKey,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getPinCode() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: pinKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let pin = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return pin
    }
    
    func verifyPinCode(_ pin: String) -> Bool {
        guard let savedPin = getPinCode() else { return false }
        return pin == savedPin
    }
    
    func removePinCode() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: pinKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Biometric Authentication
    
    var isBiometricEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: biometricEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: biometricEnabledKey) }
    }
    
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    func authenticateWithBiometric(reason: String = "Разблокировать приложение") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("❌ Biometric not available: \(error?.localizedDescription ?? "unknown")")
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            print("❌ Biometric authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Auto Lock
    
    var autoLockMinutes: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: autoLockKey)
            return value == 0 ? 5 : value // Default 5 minutes
        }
        set { UserDefaults.standard.set(newValue, forKey: autoLockKey) }
    }
    
    // MARK: - Notification Privacy
    
    var hideNotificationContent: Bool {
        get { UserDefaults.standard.bool(forKey: hideNotificationContentKey) }
        set { UserDefaults.standard.set(newValue, forKey: hideNotificationContentKey) }
    }
    
    // MARK: - Screenshot Protection
    
    var screenshotProtectionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: screenshotProtectionKey) }
        set { UserDefaults.standard.set(newValue, forKey: screenshotProtectionKey) }
    }
    
    // MARK: - App Lock State
    
    func lockApp() {
        isAppLocked = true
        requiresAuthentication = true
    }
    
    func unlockApp() {
        isAppLocked = false
        requiresAuthentication = false
    }
    
    func checkShouldLock() {
        if hasPinCode || isBiometricEnabled {
            lockApp()
        }
    }
    
    private func loadSettings() {
        // Load initial state
        if hasPinCode || isBiometricEnabled {
            isAppLocked = true
            requiresAuthentication = true
        }
    }
}

enum BiometricType {
    case none
    case faceID
    case touchID
    
    var displayName: String {
        switch self {
        case .none: return "Недоступно"
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "xmark.circle"
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        }
    }
}
