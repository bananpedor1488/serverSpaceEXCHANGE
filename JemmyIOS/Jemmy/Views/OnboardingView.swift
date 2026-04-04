import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var isEphemeral = false
    @State private var isCheckingDevice = true
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            if isCheckingDevice {
                // Loading state
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                VStack(spacing: 0) {
                Spacer()
                
                // Logo - App Icon
                if let appIcon = UIImage(named: "AppIcon") {
                    Image(uiImage: appIcon)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(24)
                        .padding(.bottom, 32)
                } else {
                    // Fallback if AppIcon not found
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 100, height: 100)
                        
                        Text("J")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 32)
                }
                
                // Title
                Text("Добро пожаловать в Jemmy")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Анонимный мессенджер для приватного общения")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                
                // Ephemeral toggle card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Временный аккаунт")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Удалится через 24 часа")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isEphemeral)
                        .labelsHidden()
                }
                .padding(20)
                .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Create button
                Button(action: {
                    print("🚀 Onboarding: Starting registration...")
                    Task {
                        await authViewModel.register(isEphemeral: isEphemeral)
                        print("✅ Onboarding: Registration complete, marking as seen")
                        hasSeenOnboarding = true
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Начать общение")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .disabled(authViewModel.isLoading)
                .padding(.bottom, 16)
                
                // Info text
                Text("Имя пользователя будет создано автоматически.\nВы сможете изменить его в настройках.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                
                Spacer()
            }
            }
        }
        .alert("Аккаунт найден", isPresented: Binding(
            get: { authViewModel.existingAccount != nil && !isCheckingDevice },
            set: { if !$0 { authViewModel.existingAccount = nil } }
        )) {
            Button("Войти") {
                Task {
                    await authViewModel.restoreAccount()
                    hasSeenOnboarding = true
                }
            }
            Button("Создать новый", role: .destructive) {
                Task {
                    await authViewModel.register(isEphemeral: false)
                    hasSeenOnboarding = true
                }
            }
        } message: {
            if let identity = authViewModel.existingAccount {
                Text("Ваш UDID устройства был найден в базе данных.\n\nАккаунт: @\(identity.username)\n\nХотите войти в этот аккаунт или создать новый?")
            }
        }
        .onAppear {
            print("👋 OnboardingView appeared")
            Task {
                await authViewModel.checkDevice()
                isCheckingDevice = false
            }
        }
    }
}
