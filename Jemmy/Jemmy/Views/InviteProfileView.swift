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
        isCreatingChat = true
        
        Task {
            do {
                // First, consume the invite link to mark it as used
                print("🔗 Consuming invite link...")
                _ = try await APIService.shared.consumeInviteLink(token: token)
                
                // Create chat with both identities
                let url = URL(string: "https://weeky-six.vercel.app/api/chat/create")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "identity_ids": [myIdentityId, identity.id],
                    "is_group": false
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 Response: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        print("✅ Chat created successfully")
                        
                        await MainActor.run {
                            dismiss()
                        }
                    } else {
                        let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                        print("❌ Server error: \(errorText)")
                    }
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
