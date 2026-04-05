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
                SecureContentView {
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
                        // Hide warning after 2 seconds
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

// Контейнер который делает контент невидимым на скриншотах (Telegram-style)
struct SecureContentView<Content: View>: UIViewControllerRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIViewController(context: Context) -> SecureViewController<Content> {
        SecureViewController(rootView: content)
    }
    
    func updateUIViewController(_ uiViewController: SecureViewController<Content>, context: Context) {
        uiViewController.updateContent(content)
    }
}

// ViewController который использует secure text field для защиты
class SecureViewController<Content: View>: UIViewController {
    private var hostingController: UIHostingController<Content>
    private var secureTextField: UITextField?
    
    init(rootView: Content) {
        self.hostingController = UIHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Добавляем secure text field для защиты
        let textField = UITextField()
        textField.isSecureTextEntry = true
        view.addSubview(textField)
        
        // Делаем его невидимым но активным
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isUserInteractionEnabled = false
        textField.alpha = 0.005 // Минимальная видимость чтобы работало
        textField.layer.sublayers?.first?.addSublayer(view.layer)
        
        // Добавляем hosting controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        self.secureTextField = textField
        
        // Делаем secure field активным
        textField.becomeFirstResponder()
        textField.resignFirstResponder()
    }
    
    func updateContent(_ content: Content) {
        hostingController.rootView = content
    }
}

extension View {
    func screenshotProtection(enabled: Bool) -> some View {
        modifier(ScreenshotProtectionModifier(isEnabled: enabled))
    }
}
