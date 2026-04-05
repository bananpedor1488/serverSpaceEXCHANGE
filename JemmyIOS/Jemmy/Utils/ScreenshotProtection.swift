import SwiftUI
import UIKit

// Модификатор для защиты от скриншотов (рабочая реализация)
struct ScreenshotProtectionModifier: ViewModifier {
    let isEnabled: Bool
    let onScreenshotDetected: (() -> Void)?
    @State private var showScreenshotWarning = false
    @State private var hostingController: UIHostingController<AnyView>?
    
    func body(content: Content) -> some View {
        Group {
            if isEnabled {
                ScreenshotPreventView {
                    content
                }
            } else {
                content
            }
        }
        .overlay(
            Group {
                if showScreenshotWarning && isEnabled {
                    ZStack {
                        Color.black.opacity(0.8)
                        
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                            
                            Text("Скриншот обнаружен")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Собеседник включил защиту от скриншотов")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .ignoresSafeArea()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showScreenshotWarning = false
                            }
                        }
                    }
                }
            }
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
            withAnimation {
                showScreenshotWarning = true
            }
            // Вызываем callback для отправки уведомления
            onScreenshotDetected?()
        }
    }
    
    private func stopMonitoring() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }
}

// View который предотвращает скриншоты (как в Telegram)
struct ScreenshotPreventView<Content: View>: View {
    var content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    @State private var hostingController: UIHostingController<Content>?
    
    var body: some View {
        _ScreenshotPreventHelper(hostingController: $hostingController)
            .overlay(
                GeometryReader { geometry in
                    let size = geometry.size
                    Color.clear
                        .preference(key: SizeKey.self, value: size)
                        .onPreferenceChange(SizeKey.self) { newValue in
                            if hostingController == nil {
                                hostingController = UIHostingController(rootView: content)
                                hostingController?.view.backgroundColor = .clear
                                hostingController?.view.frame = CGRect(origin: .zero, size: size)
                            } else {
                                hostingController?.view.frame = CGRect(origin: .zero, size: newValue)
                            }
                        }
                }
            )
    }
}

// PreferenceKey для отслеживания размера
fileprivate struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Helper который использует secure text field
fileprivate struct _ScreenshotPreventHelper<Content: View>: UIViewRepresentable {
    @Binding var hostingController: UIHostingController<Content>?
    
    func makeUIView(context: Context) -> UIView {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true
        
        // Получаем внутренний TextLayoutView который имеет secure свойства
        if let textLayoutView = secureField.subviews.first {
            return textLayoutView
        }
        
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Добавляем hosting view как subview к TextLayout view
        if let hostingController, !uiView.subviews.contains(where: { $0 == hostingController.view }) {
            // Удаляем старые subviews
            uiView.subviews.forEach { $0.removeFromSuperview() }
            
            // Добавляем новый
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            uiView.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: uiView.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: uiView.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: uiView.bottomAnchor)
            ])
        }
    }
}

extension View {
    func screenshotProtection(enabled: Bool, onScreenshotDetected: (() -> Void)? = nil) -> some View {
        modifier(ScreenshotProtectionModifier(isEnabled: enabled, onScreenshotDetected: onScreenshotDetected))
    }
}
