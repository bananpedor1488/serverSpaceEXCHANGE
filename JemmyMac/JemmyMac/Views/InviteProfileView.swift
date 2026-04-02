import SwiftUI

struct InviteProfileView: View {
    let identity: Identity
    let token: String
    @Binding var createdChat: CreatedChat?
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Avatar
                if let url = URL(string: identity.avatar) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                }
                
                // Username
                Text("@\(identity.username)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Bio
                if !identity.bio.isEmpty {
                    Text(identity.bio)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Start Chat Button
                Button(action: startChat) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "message.fill")
                            Text("Начать чат")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .padding(.top, 50)
        }
    }
    
    private func startChat() {
        guard let myIdentityId = authViewModel.identity?.id else {
            print("❌ No identity")
            return
        }
        
        isLoading = true
        print("📡 start chat:", token)
        
        Task {
            do {
                let response = try await APIService.shared.startChat(token: token, myIdentityId: myIdentityId)
                
                await MainActor.run {
                    print("✅ чат создан:", response.chatId)
                    createdChat = CreatedChat(chatId: response.chatId, otherUser: response.otherUser)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("❌ error:", error.localizedDescription)
                    isLoading = false
                }
            }
        }
    }
}
