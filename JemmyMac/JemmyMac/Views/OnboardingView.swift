import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground()
            
            // Frosted glass effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 24) {
                    // App icon
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .white.opacity(0.3), radius: 20)
                    
                    VStack(spacing: 12) {
                        Text("Jemmy")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Анонимный мессенджер")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                VStack(spacing: 20) {
                    FeatureRow(icon: "lock.shield.fill", text: "Полная анонимность")
                    FeatureRow(icon: "clock.arrow.circlepath", text: "Временные личности")
                    FeatureRow(icon: "key.fill", text: "End-to-end шифрование")
                }
                .padding(.horizontal, 60)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasSeenOnboarding = true
                    }
                    Task {
                        await authViewModel.register()
                    }
                }) {
                    Text("Продолжить")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 40)
            
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}
