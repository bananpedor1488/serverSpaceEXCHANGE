import SwiftUI
import AppKit

struct LinkGeneratorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var generatedLink: String?
    @State private var linkExpiresAt: Date?
    @State private var isGenerating = false
    @State private var showCopied = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Создать ссылку")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Icon
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 50))
                        )
                        .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        Text("Одноразовая ссылка")
                            .font(.system(size: 24, weight: .semibold))
                        
                        Text("Создай ссылку для начала чата.\nОна действует 24 часа.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let link = generatedLink, let expiresAt = linkExpiresAt {
                        VStack(spacing: 16) {
                            // Expiry timer
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
                            
                            Text(link)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                Button(action: copyLink) {
                                    HStack {
                                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        Text(showCopied ? "Скопировано" : "Копировать")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor.opacity(showCopied ? 0.3 : 0.2))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                            
                            Button(action: clearLink) {
                                Text("Создать новую ссылку")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                        }
                    } else {
                        Button(action: generateLink) {
                            HStack(spacing: 8) {
                                if isGenerating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Создать ссылку")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .disabled(isGenerating)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            loadSavedLink()
        }
    }
    
    private func timeRemaining(until date: Date) -> String {
        let hours = Int(date.timeIntervalSinceNow / 3600)
        let minutes = Int((date.timeIntervalSinceNow.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "Осталось \(hours)ч \(minutes)м"
        } else if minutes > 0 {
            return "Осталось \(minutes)м"
        } else {
            return "Истекла"
        }
    }
    
    private func loadSavedLink() {
        guard let identityId = authViewModel.identity?.id else { return }
        
        let linkKey = "invite_link_\(identityId)"
        let expiryKey = "invite_link_expiry_\(identityId)"
        
        if let savedLink = UserDefaults.standard.string(forKey: linkKey),
           let expiryTimestamp = UserDefaults.standard.object(forKey: expiryKey) as? Double {
            
            let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)
            
            if expiryDate > Date() {
                print("✅ Loaded saved link")
                generatedLink = savedLink
                linkExpiresAt = expiryDate
            } else {
                clearLink()
            }
        }
    }
    
    private func saveLink(_ link: String) {
        guard let identityId = authViewModel.identity?.id else { return }
        
        let linkKey = "invite_link_\(identityId)"
        let expiryKey = "invite_link_expiry_\(identityId)"
        let expiryDate = Date().addingTimeInterval(24 * 60 * 60)
        
        UserDefaults.standard.set(link, forKey: linkKey)
        UserDefaults.standard.set(expiryDate.timeIntervalSince1970, forKey: expiryKey)
        
        print("💾 Link saved")
    }
    
    private func clearLink() {
        guard let identityId = authViewModel.identity?.id else { return }
        
        let linkKey = "invite_link_\(identityId)"
        let expiryKey = "invite_link_expiry_\(identityId)"
        
        UserDefaults.standard.removeObject(forKey: linkKey)
        UserDefaults.standard.removeObject(forKey: expiryKey)
        
        generatedLink = nil
        linkExpiresAt = nil
        
        print("🗑️ Link cleared")
    }
    
    private func generateLink() {
        guard let identityId = authViewModel.identity?.id else { return }
        
        print("🔗 Generating invite link...")
        isGenerating = true
        
        Task {
            do {
                let link = try await APIService.shared.generateInviteLink(identityId: identityId)
                
                await MainActor.run {
                    let expiryDate = Date().addingTimeInterval(24 * 60 * 60)
                    generatedLink = link
                    linkExpiresAt = expiryDate
                    saveLink(link)
                    print("✅ Link displayed")
                }
            } catch {
                print("❌ Link generation failed")
            }
            
            await MainActor.run {
                isGenerating = false
            }
        }
    }
    
    private func copyLink() {
        if let link = generatedLink {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(link, forType: .string)
            print("📋 Link copied")
            
            showCopied = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCopied = false
            }
        }
    }
}
