import SwiftUI

struct PinCodeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var privacyManager = PrivacyManager.shared
    
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var step: SetupStep = .enter
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum SetupStep {
        case enter
        case confirm
        case verify
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Title
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text(titleText)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitleText)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // PIN dots
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < currentPin.count ? Color.white : Color.white.opacity(0.2))
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.vertical, 32)
                
                Spacer()
                
                // Numpad
                VStack(spacing: 16) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 16) {
                            ForEach(1...3, id: \.self) { col in
                                let number = row * 3 + col
                                NumpadButton(number: "\(number)") {
                                    addDigit(number)
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        // Empty space
                        Color.clear
                            .frame(width: 80, height: 80)
                        
                        NumpadButton(number: "0") {
                            addDigit(0)
                        }
                        
                        // Delete button
                        Button(action: deleteDigit) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                        }
                    }
                }
                .padding(.bottom, 32)
                
                // Remove PIN button (if exists)
                if privacyManager.hasPinCode && step == .verify {
                    Button(action: removePin) {
                        Text("Удалить PIN-код")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) {
                resetCurrentPin()
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if privacyManager.hasPinCode {
                step = .verify
            }
        }
    }
    
    private var titleText: String {
        switch step {
        case .enter:
            return "Создать PIN-код"
        case .confirm:
            return "Подтвердите PIN-код"
        case .verify:
            return "Введите PIN-код"
        }
    }
    
    private var subtitleText: String {
        switch step {
        case .enter:
            return "Введите 4-значный PIN-код"
        case .confirm:
            return "Введите PIN-код еще раз"
        case .verify:
            return "Введите текущий PIN-код"
        }
    }
    
    private var currentPin: String {
        switch step {
        case .enter, .verify:
            return pin
        case .confirm:
            return confirmPin
        }
    }
    
    private func addDigit(_ digit: Int) {
        let digitString = "\(digit)"
        
        switch step {
        case .enter:
            if pin.count < 4 {
                pin += digitString
                if pin.count == 4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        step = .confirm
                    }
                }
            }
            
        case .confirm:
            if confirmPin.count < 4 {
                confirmPin += digitString
                if confirmPin.count == 4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        verifyAndSave()
                    }
                }
            }
            
        case .verify:
            if pin.count < 4 {
                pin += digitString
                if pin.count == 4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        verifyExisting()
                    }
                }
            }
        }
    }
    
    private func deleteDigit() {
        switch step {
        case .enter, .verify:
            if !pin.isEmpty {
                pin.removeLast()
            }
        case .confirm:
            if !confirmPin.isEmpty {
                confirmPin.removeLast()
            }
        }
    }
    
    private func resetCurrentPin() {
        switch step {
        case .enter, .verify:
            pin = ""
        case .confirm:
            confirmPin = ""
        }
    }
    
    private func verifyAndSave() {
        if pin == confirmPin {
            if privacyManager.setPinCode(pin) {
                dismiss()
            } else {
                errorMessage = "Не удалось сохранить PIN-код"
                showError = true
            }
        } else {
            errorMessage = "PIN-коды не совпадают"
            showError = true
            step = .enter
            pin = ""
            confirmPin = ""
        }
    }
    
    private func verifyExisting() {
        if privacyManager.verifyPinCode(pin) {
            // Correct PIN, allow to change
            pin = ""
            step = .enter
        } else {
            errorMessage = "Неверный PIN-код"
            showError = true
        }
    }
    
    private func removePin() {
        if privacyManager.removePinCode() {
            dismiss()
        } else {
            errorMessage = "Не удалось удалить PIN-код"
            showError = true
        }
    }
}

struct NumpadButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}
