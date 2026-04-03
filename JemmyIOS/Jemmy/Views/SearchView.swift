import SwiftUI

struct SearchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchUsername = ""
    @State private var foundIdentity: Identity?
    @State private var isSearching = false
    @State private var isCreatingChat = false
    @State private var showError = false
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
                            
                            TextField("Введи username", text: $searchUsername)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            if !searchUsername.isEmpty {
                                Button(action: { searchUsername = "" }) {
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
                        
                        if let identity = foundIdentity {
                            VStack(spacing: 20) {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(String(identity.username.prefix(2)).uppercased())
                                            .font(.system(size: 32, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(spacing: 8) {
                                    Text(identity.username)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                if !identity.bio.isEmpty {
                                    Text(identity.bio)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                                
                                Button(action: startDirectChat) {
                                    HStack(spacing: 8) {
                                        if isCreatingChat {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text("Начать чат")
                                                .font(.system(size: 17, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                                .disabled(isCreatingChat)
                            }
                            .padding(.vertical, 24)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .alert("Не найдено", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Пользователь \(searchUsername) не найден")
        }
    }
    
    private func searchByUsername() {
        isSearching = true
        Task {
            do {
                let url = URL(string: "https://weeky-six.vercel.app/api/identity/search/\(searchUsername)")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let identity = try JSONDecoder().decode(Identity.self, from: data)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        foundIdentity = identity
                    }
                }
            } catch {
                await MainActor.run {
                    showError = true
                    foundIdentity = nil
                }
            }
            await MainActor.run {
                isSearching = false
            }
        }
    }
    
    private func startDirectChat() {
        guard let myIdentityId = authViewModel.identity?.id,
              let otherIdentity = foundIdentity else {
            print("❌ Missing identity")
            return
        }
        
        isCreatingChat = true
        print("📡 Creating direct chat with:", otherIdentity.username)
        
        Task {
            do {
                let response = try await APIService.shared.startDirectChat(
                    myIdentityId: myIdentityId,
                    otherIdentityId: otherIdentity.id
                )
                
                await MainActor.run {
                    print("✅ чат создан:", response.chatId)
                    createdChat = CreatedChat(chatId: response.chatId, otherUser: response.otherUser)
                    isCreatingChat = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("❌ error:", error.localizedDescription)
                    isCreatingChat = false
                }
            }
        }
    }
}
