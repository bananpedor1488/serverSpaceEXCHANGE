import SwiftUI
import UIKit

// Модификатор для защиты от скриншотов
struct ScreenshotProtectionModifier: ViewModifier {
    let isEnabled: Bool
    @State private var isCapturing = false
    @State private var secureField: UITextField?
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isCapturing && isEnabled ? 20 : 0)
            .overlay(
                Group {
                    if isCapturing && isEnabled {
                        ZStack {
                            Color.black.opacity(0.8)
                            
                            VStack(spacing: 16) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("Защита от скриншотов")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Собеседник включил защиту")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .ignoresSafeArea()
                    }
                }
            )
            .background(
                // Используем UITextField с secureTextEntry для дополнительной защиты
                SecureFieldRepresentable(isEnabled: isEnabled, secureField: $secureField)
            )
            .onAppear {
                if isEnabled {
                    print("🔒 Screenshot protection ENABLED")
                    startMonitoring()
                } else {
                    print("🔓 Screenshot protection DISABLED")
                }
            }
            .onDisappear {
                stopMonitoring()
            }
    }
    
    private func startMonitoring() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("📸 Screenshot detected!")
            // Можно добавить уведомление собеседнику
        }
        
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                isCapturing = UIScreen.main.isCaptured
                print("🎥 Screen recording: \(isCapturing)")
            }
        }
        
        // Check initial state
        isCapturing = UIScreen.main.isCaptured
    }
    
    private func stopMonitoring() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
    }
}

// UITextField с secureTextEntry для дополнительной защиты
struct SecureFieldRepresentable: UIViewRepresentable {
    let isEnabled: Bool
    @Binding var secureField: UITextField?
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.isSecureTextEntry = isEnabled
        textField.isUserInteractionEnabled = false
        textField.alpha = 0
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.isSecureTextEntry = isEnabled
        DispatchQueue.main.async {
            secureField = uiView
        }
    }
}

extension View {
    func screenshotProtection(enabled: Bool) -> some View {
        modifier(ScreenshotProtectionModifier(isEnabled: enabled))
    }
}
