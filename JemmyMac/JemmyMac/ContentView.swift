import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if authViewModel.identity != nil {
                HomeView()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .task {
                        await authViewModel.register()
                    }
            }
        }
    }
}
