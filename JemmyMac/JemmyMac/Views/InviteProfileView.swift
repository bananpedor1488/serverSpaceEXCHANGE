import SwiftUI

struct InviteProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    let identity: Identity
    @State private var isCreatingChat = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Profile info
                    VStack(spacing: 20) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text(String(identity.username.prefix(2)).uppercased())
                                    .font(.system(size: 48, weight: .semibold))
                            )
                        
                        VStack(spacing: 8) {
                            Text(identity.username)
                                .font(.system(size: 32, weight: .semibold))
                            
                            if !identity.bio.isEmpty {
                                Text(identity.bio)
                                    .font(.system(size: 17))
                                    .foregroundColor(.secondary)
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
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 18))
                                Text("Начать чат")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCreatingChat)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    
                    Spacer()
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
        isCreatingChat = true
        
        Task {
            do {
                let chat = try await APIService.shared.createChat(identityIds: [myIdentityId, identity.id])
                print("✅ Chat created successfully")
                
                await MainActor.run {
                    authViewModel.chats.append(chat)
                    dismiss()
                }
            } catch {
                print("❌ Failed to create chat: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                isCreatingChat = false
            }
        }
    }
}
