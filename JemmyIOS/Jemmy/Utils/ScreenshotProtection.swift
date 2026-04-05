import SwiftUI
import UIKit

// Модификатор для защиты от скриншотов
struct ScreenshotProtectionModifier: ViewModifier {
    let isEnabled: Bool
    @State private var isCapturing = false
    
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
            .onAppear {
                if isEnabled {
                    startMonitoring()
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

extension View {
    func screenshotProtection(enabled: Bool) -> some View {
        modifier(ScreenshotProtectionModifier(isEnabled: enabled))
    }
}
