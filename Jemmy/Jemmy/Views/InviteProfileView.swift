import SwiftUI

struct InviteProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    let identity: Identity
    let token: String
    @State private var isCreatingChat = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    Button(action: {
                        print("❌ Invite profile dismissed")
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile info
                        VStack(spacing: 20) {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text(String(identity.username.prefix(2)).uppercased())
                                        .font(.system(size: 48, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(spacing: 8) {
                                Text(identity.username)
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                if !identity.bio.isEmpty {
                                    Text(identity.bio)
                                        .font(.system(size: 17))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.top, 40)
                        
                        // Start chat button
                        Button(action: startChat) {
                            HStack(spacing: 12) {
                                if isCreatingChat {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 20))
                                    Text("Начать чат")
                                        .font(.system(size: 19, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(16)
                        }
                        .disabled(isCreatingChat)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func startChat() {
        guard let myIdentityId = authViewModel.identity?.id else {
            print("⚠️ Cannot start chat: no identity")
            return
        }
        
        print("💬 Starting chat with \(identity.username)...")
        print("📡 start chat:", token)
        isCreatingChat = true
        
        Task {
            do {
                let chatResponse = try await APIService.shared.startChat(token: token, myIdentityId: myIdentityId)
                
                print("✅ чат создан:", chatResponse.chatId)
                
                await MainActor.run {
                    isCreatingChat = false
                    dismiss()
                    // TODO: Navigate to chat view with chatResponse.chatId
                }
            } catch {
                print("❌ error:", error.localizedDescription)
                await MainActor.run {
                    isCreatingChat = false
                }
            }
        }
    }
}
