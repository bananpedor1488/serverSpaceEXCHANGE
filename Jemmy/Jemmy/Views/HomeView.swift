import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @Binding var openChat: (chatId: String, otherUser: Identity)?
    
    var body: some View {
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

struct ChatsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var chats: [Chat] = []
    @State private var searchText = ""
    @State private var isSearchExpanded = false
    @State private var showSearchByTag = false
    @FocusState private var isSearchFocused: Bool
    
    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chats
        }
        return chats.filter { chat in
            chat.groupName?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar with expand animation
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 16))
                        
                        TextField("Поиск", text: $searchText)
                            .foregroundColor(.white)
                            .font(.system(size: 17))
                            .focused($isSearchFocused)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSearchExpanded = true
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSearchExpanded = false
                                    isSearchFocused = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, isSearchExpanded ? 8 : 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    
                    // Chats list
                    if filteredChats.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.2))
                            
                            Text(searchText.isEmpty ? "Нет чатов" : "Ничего не найдено")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 1) {
                                ForEach(filteredChats) { chat in
                                    ChatRow(chat: chat)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Чаты")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSearchByTag = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showSearchByTag) {
                SearchView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String((chat.groupName ?? "?").prefix(1)))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(chat.groupName ?? "Чат")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Последнее сообщение...")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("12:34")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
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
