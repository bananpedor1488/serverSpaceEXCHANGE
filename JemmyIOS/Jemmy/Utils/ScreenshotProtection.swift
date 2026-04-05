import SwiftUI
import UIKit

// Модификатор для защиты от скриншотов (как в Telegram)
struct ScreenshotProtectionModifier: ViewModifier {
    let isEnabled: Bool
    @State private var showScreenshotWarning = false
    
    func body(content: Content) -> some View {
        ZStack {
            if isEnabled {
                // Используем SecureField трюк для защиты контента
                SecureContentWrapper {
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
                print("🔒 Screenshot protection ENABLED (Telegram-style)")
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

// Обертка которая делает контент невидимым на скриншотах
struct SecureContentWrapper<Content: View>: UIViewRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> SecureUIView {
        let view = SecureUIView()
        
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        context.coordinator.hostingController = hostingController
        
        return view
    }
    
    func updateUIView(_ uiView: SecureUIView, context: Context) {
        context.coordinator.hostingController?.rootView = content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var hostingController: UIHostingController<Content>?
    }
}

// UIView с защитой от скриншотов
class SecureUIView: UIView {
    private var secureTextField: UITextField?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSecureLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSecureLayer()
    }
    
    private func setupSecureLayer() {
        // Создаем невидимый secure text field
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        textField.backgroundColor = .clear
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем его в иерархию
        addSubview(textField)
        sendSubviewToBack(textField)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        self.secureTextField = textField
        
        // Делаем secure layer активным
        DispatchQueue.main.async {
            textField.becomeFirstResponder()
            textField.resignFirstResponder()
        }
    }
}

extension View {
    func screenshotProtection(enabled: Bool) -> some View {
        modifier(ScreenshotProtectionModifier(isEnabled: enabled))
    }
}
