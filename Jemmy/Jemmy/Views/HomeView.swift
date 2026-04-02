import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @Binding var openChat: CreatedChat?
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ChatsListView(openChat: $openChat)
                    .environmentObject(authViewModel)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                        Text("Чаты")
                    }
                    .tag(0)
                
                ProfileView()
                    .environmentObject(authViewModel)
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "person.crop.square.fill" : "person.crop.square")
                        Text("Профиль")
                    }
                    .tag(1)
            }
            .accentColor(.white)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showLinkGenerator = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile header
                        VStack(spacing: 20) {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Group {
                                        if let identity = authViewModel.identity {
                                            Text(String(identity.username.prefix(2)).uppercased())
                                                .font(.system(size: 40, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                )
                            
                            if let identity = authViewModel.identity {
                                VStack(spacing: 8) {
                                    Text(identity.username)
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    if !identity.bio.isEmpty {
                                        Text(identity.bio)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                            .padding(.top, 4)
                                    }
                                    
                                    if authViewModel.ephemeralEnabled, let expiresAt = identity.expiresAt {
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock")
                                            Text(timeRemaining(until: expiresAt))
                                        }
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.orange.opacity(0.15))
                                        .cornerRadius(8)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                        }
                        .padding(.top, 40)
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                print("🔗 Opening link generator")
                                showLinkGenerator = true
                            }) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.system(size: 18))
                                    Text("Создать ссылку")
                                        .font(.system(size: 17, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                print("✏️ Opening profile editor")
                                showEditProfile = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 18))
                                    Text("Редактировать профиль")
                                        .font(.system(size: 17, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Settings
                        VStack(spacing: 12) {
                            Toggle(isOn: Binding(
                                get: { authViewModel.ephemeralEnabled },
                                set: { newValue in
                                    print("🔄 Ephemeral toggle changed to: \(newValue)")
                                    Task {
                                        await authViewModel.toggleEphemeral()
                                    }
                                }
                            )) {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ephemeral Identity")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Личность меняется каждые 24 часа")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }
                            .tint(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Delete account button
                            Button(action: {
                                print("⚠️ Delete account button tapped")
                                showDeleteAlert = true
                            }) {
                                HStack {
                                    if isDeleting {
                                        ProgressView()
                                            .tint(.red)
                                    } else {
                                        Image(systemName: "trash")
                                            .font(.system(size: 18))
                                        Text("Удалить аккаунт")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    Spacer()
                                }
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .disabled(isDeleting)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showEditProfile) {
                if let identity = authViewModel.identity {
                    ProfileEditView(identity: identity)
                        .environmentObject(authViewModel)
                }
            }
            .sheet(isPresented: $showLinkGenerator) {
                LinkGeneratorView()
                    .environmentObject(authViewModel)
            }
            .alert("Удалить аккаунт?", isPresented: $showDeleteAlert) {
                Button("Отмена", role: .cancel) {
                    print("❌ Account deletion cancelled")
                }
                Button("Удалить", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Все ваши данные будут удалены безвозвратно")
            }
        }
        .onAppear {
            print("👤 ProfileView appeared")
            if let identity = authViewModel.identity {
                print("   Username: \(identity.username)")
            }
        }
    }
    
    private func timeRemaining(until date: Date) -> String {
        let hours = Int(date.timeIntervalSinceNow / 3600)
        return hours > 0 ? "Осталось \(hours)ч" : "Скоро обновится"
    }
    
    private func deleteAccount() {
        print("🗑️ Starting account deletion...")
        isDeleting = true
        
        Task {
            do {
                try await authViewModel.deleteAccount()
                print("✅ Account deleted, UI will reset")
            } catch {
                print("❌ Account deletion failed in UI")
            }
            
            await MainActor.run {
                isDeleting = false
            }
        }
    }
}
