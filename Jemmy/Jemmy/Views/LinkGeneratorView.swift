import SwiftUI

struct LinkGeneratorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var generatedLink: String?
    @State private var isGenerating = false
    @State private var showCopied = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        print("❌ Link generator closed")
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                    
                    Text("Создать ссылку")
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
                    VStack(spacing: 32) {
                        // Icon
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                            .padding(.top, 40)
                        
                        VStack(spacing: 12) {
                            Text("Одноразовая ссылка")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Создай ссылку для начала чата.\nОна действует 24 часа.")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        
                        if let link = generatedLink {
                            VStack(spacing: 16) {
                                Text(link)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal, 20)
                                
                                HStack(spacing: 12) {
                                    Button(action: copyLink) {
                                        HStack {
                                            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                            Text(showCopied ? "Скопировано" : "Копировать")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.white.opacity(showCopied ? 0.2 : 0.15))
                                        .cornerRadius(12)
                                    }
                                    
                                    Button(action: shareLink) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Поделиться")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            Button(action: generateLink) {
                                HStack(spacing: 8) {
                                    if isGenerating {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Создать ссылку")
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
                            .disabled(isGenerating)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            print("🔗 LinkGeneratorView appeared")
        }
    }
    
    private func generateLink() {
        guard let identityId = authViewModel.identity?.id else {
            print("❌ Cannot generate link: no identity ID")
            return
        }
        
        print("🔗 Generating invite link...")
        isGenerating = true
        
        Task {
            do {
                let link = try await APIService.shared.generateInviteLink(identityId: identityId)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        generatedLink = link
                    }
                    print("✅ Link displayed in UI")
                }
            } catch {
                print("❌ Link generation failed in UI")
            }
            
            await MainActor.run {
                isGenerating = false
            }
        }
    }
    
    private func copyLink() {
        if let link = generatedLink {
            UIPasteboard.general.string = link
            print("📋 Link copied to clipboard: \(link)")
            
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopied = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCopied = false
                }
            }
        }
    }
    
    private func shareLink() {
        guard let link = generatedLink else { return }
        
        print("📤 Sharing link: \(link)")
        
        let activityVC = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
