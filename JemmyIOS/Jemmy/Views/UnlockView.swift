import SwiftUI
import LocalAuthentication

struct UnlockView: View {
    @EnvironmentObject var privacyManager: PrivacyManager
    @State private var enteredPin = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                // Title
                Text("Введите PIN-код")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                // PIN dots
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < enteredPin.count ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.vertical, 20)
                
                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.red)
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Biometric button
                if privacyManager.isBiometricEnabled && privacyManager.biometricType != .none {
                    Button(action: authenticateWithBiometric) {
                        HStack {
                            Image(systemName: privacyManager.biometricType.icon)
                                .font(.system(size: 20))
                            Text("Использовать \(privacyManager.biometricType.displayName)")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                    }
                    .disabled(isAuthenticating)
                    .padding(.bottom, 20)
                }
                
                // Number pad
                VStack(spacing: 15) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 15) {
                            ForEach(1..<4) { col in
                                let number = row * 3 + col
                                NumberButton(number: "\(number)") {
                                    addDigit("\(number)")
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 15) {
                        // Empty space
                        Color.clear
                            .frame(width: 80, height: 80)
                        
                        // 0
                        NumberButton(number: "0") {
                            addDigit("0")
                        }
                        
                        // Delete
                        Button(action: deleteDigit) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Try biometric on appear if enabled
            if privacyManager.isBiometricEnabled && privacyManager.biometricType != .none {
                Task {
                    await authenticateWithBiometric()
                }
            }
        }
    }
    
    private func addDigit(_ digit: String) {
        guard enteredPin.count < 4 else { return }
        
        enteredPin += digit
        showError = false
        
        if enteredPin.count == 4 {
            verifyPin()
        }
    }
    
    private func deleteDigit() {
        if !enteredPin.isEmpty {
            enteredPin.removeLast()
            showError = false
        }
    }
    
    private func verifyPin() {
        if privacyManager.verifyPinCode(enteredPin) {
            print("✅ PIN correct - unlocking app")
            withAnimation {
                privacyManager.unlockApp()
            }
        } else {
            print("❌ PIN incorrect")
            errorMessage = "Неверный PIN-код"
            showError = true
            enteredPin = ""
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    private func authenticateWithBiometric() {
        guard !isAuthenticating else { return }
        
        isAuthenticating = true
        
        Task {
            let success = await privacyManager.authenticateWithBiometric()
            
            await MainActor.run {
                isAuthenticating = false
                
                if success {
                    print("✅ Biometric authentication successful")
                    withAnimation {
                        privacyManager.unlockApp()
                    }
                } else {
                    print("❌ Biometric authentication failed")
                    errorMessage = "Не удалось выполнить биометрическую аутентификацию"
                    showError = true
                }
            }
        }
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}
