import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var step = 0
    @State private var navigateToHome = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                if step >= 0 {
                    Text("Ты никто.")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
                
                if step >= 1 {
                    Text("Но ты можешь стать кем угодно.")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
                
                if step >= 2 {
                    Button(action: {
                        Task {
                            await viewModel.register()
                            navigateToHome = true
                        }
                    }) {
                        Text("Начать")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .transition(.move(edge: .trailing))
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                step = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 1.0)) {
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
