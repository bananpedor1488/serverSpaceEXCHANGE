import SwiftUI
import AppKit

struct LinkGeneratorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var generatedLink: String?
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
                                .foregroundColor(.accentColor)
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
                    
                    if let link = generatedLink {
                        VStack(spacing: 16) {
                            Text(link)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
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
                                    .background(showCopied ? Color.green.opacity(0.2) : Color.accentColor.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: shareLink) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Поделиться")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                        }
                        .transition(.scale.combined(with: .opacity))
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
                            .frame(maxWidth: 300)
                            .padding(.vertical, 14)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(isGenerating)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private func generateLink() {
        guard let identityId = authViewModel.identity?.id else { return }
        
        isGenerating = true
        Task {
            do {
                let url = URL(string: "https://weeky-six.vercel.app/api/identity/generate-link")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = ["identity_id": identityId]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let link = response?["link"] as? String {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            generatedLink = link
                        }
                    }
                }
            } catch {
                print("Generate link error: \(error)")
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
        let picker = NSSharingServicePicker(items: [link])
        if let view = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
}
