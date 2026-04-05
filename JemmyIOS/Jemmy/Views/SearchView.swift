import SwiftUI

struct SearchResponse: Codable {
    let results: [Identity]
}

struct SearchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchUsername = ""
    @State private var foundIdentities: [Identity] = []
    @State private var isSearching = false
    @State private var creatingChatForId: String?
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var createdChat: CreatedChat?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                    
                    Text("Найти пользователя")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Search field
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.5))
                            
                            TextField("Введи username (с @ или без)", text: $searchUsername)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            if !searchUsername.isEmpty {
                                Button(action: { 
                                    searchUsername = ""
                                    foundIdentities = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Button(action: searchByUsername) {
                            HStack(spacing: 8) {
                                if isSearching {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Найти")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .disabled(searchUsername.isEmpty || isSearching)
                        
                        // Results list
                        if !foundIdentities.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(foundIdentities) { identity in
                                    UserSearchResultRow(
                                        identity: identity,
                                        isCreatingChat: creatingChatForId == identity.id,
                                        onClick: {
                                            startDirectChat(with: identity)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func searchByUsername() {
        guard let myIdentityId = authViewModel.identity?.id else {
            errorMessage = "Не удалось получить ваш ID"
            showError = true
            return
        }
        
        isSearching = true
        foundIdentities = []
        
        Task {
            do {
                // Убираем @ если есть
                let cleanUsername = searchUsername.hasPrefix("@") ? String(searchUsername.dropFirst()) : searchUsername
                
                var urlComponents = URLComponents(string: "https://weeky-six.vercel.app/api/identity/search/\(cleanUsername)")!
                urlComponents.queryItems = [
                    URLQueryItem(name: "current_identity_id", value: myIdentityId)
                ]
                
                let (data, _) = try await URLSession.shared.data(from: urlComponents.url!)
                let response = try JSONDecoder().decode(SearchResponse.self, from: data)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if response.results.isEmpty {
                            errorMessage = "Пользователи не найдены"
                            showError = true
                        } else {
                            foundIdentities = response.results
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Ошибка поиска: \(error.localizedDescription)"
                    showError = true
                    foundIdentities = []
                }
            }
            await MainActor.run {
                isSearching = false
            }
        }
    }
    
    private func startDirectChat(with identity: Identity) {
        guard let myIdentityId = authViewModel.identity?.id else {
            print("❌ Missing identity")
            return
        }
        
        creatingChatForId = identity.id
        print("📡 Creating direct chat with:", identity.username)
        
        Task {
            do {
                let response = try await APIService.shared.startDirectChat(
                    myIdentityId: myIdentityId,
                    otherIdentityId: identity.id
                )
                
                await MainActor.run {
                    print("✅ чат создан:", response.chatId)
                    createdChat = CreatedChat(chatId: response.chatId, otherUser: response.otherUser)
                    creatingChatForId = nil
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("❌ error:", error.localizedDescription)
                    errorMessage = "Не удалось создать чат"
                    showError = true
                    creatingChatForId = nil
                }
            }
        }
    }
}

struct UserSearchResultRow: View {
    let identity: Identity
    let isCreatingChat: Bool
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                AvatarView(identity: identity, size: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("@\(identity.username)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    if !identity.bio.isEmpty {
                        Text(identity.bio)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isCreatingChat {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .disabled(isCreatingChat)
    }
}
