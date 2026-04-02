import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var step = 0
    @State private var navigateToHome = false
    @State private var gradientOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.0, blue: 0.3),
                    Color(red: 0.0, green: 0.1, blue: 0.4),
                    Color(red: 0.2, green: 0.0, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(gradientOffset))
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                    gradientOffset = 360
                }
            }
            
            // Floating particles
            ForEach(0..<20, id: \.self) { i in
                FloatingParticle(delay: Double(i) * 0.3)
            }
            
            // Glass morphism overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 50) {
                Spacer()
                
                if step >= 0 {
                    Text("Ты никто.")
                        .font(.system(size: 42, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .transition(.opacity.combined(with: .scale))
                }
                
                if step >= 1 {
                    Text("Но ты можешь стать\nкем угодно.")
                        .font(.system(size: 42, weight: .ultraLight, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
                
                if step >= 2 {
                    Button(action: {
                        Task {
                            await viewModel.register()
                            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                            navigateToHome = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Начать")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.5), radius: 20, y: 10)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                step = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    step = 2
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToHome) {
            HomeView()
                .environmentObject(viewModel)
        }
    }
}

struct FloatingParticle: View {
    let delay: Double
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.1))
            .frame(width: CGFloat.random(in: 20...60))
            .blur(radius: CGFloat.random(in: 5...15))
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                let randomX = CGFloat.random(in: -150...150)
                let randomY = CGFloat.random(in: -300...300)
                
                withAnimation(
                    .easeInOut(duration: Double.random(in: 8...15))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    xOffset = randomX
                    yOffset = randomY
                    opacity = Double.random(in: 0.3...0.7)
                }
            }
    }
}
