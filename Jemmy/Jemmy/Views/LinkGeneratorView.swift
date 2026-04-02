import SwiftUI

struct LinkGeneratorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var generatedLink: String?
    @State private var isGenerating = false
    @State private var showCopied = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(colorScheme == .dark ? .black : .white)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        Text("Одноразовая ссылка")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("Создай ссылку для начала чата.\nОна действует 24 часа.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let link = generatedLink {
                        VStack(spacing: 16) {
                            Text(link)
                                .font(.system(size: 13, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            
                            Button(action: copyLink) {
                                HStack {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                    Text(showCopied ? "Скопировано!" : "Копировать")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(showCopied ? Color.green : Color.blue)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Button(action: generateLink) {
                            HStack {
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
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 15, y: 8)
                        }
                        .padding(.horizontal, 40)
                        .disabled(isGenerating)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Пригласить")
            .navigationBarTitleDisplayMode(.inline)
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
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        generatedLink = link
                    }
                }
            } catch {
                print("Generate link error: \(error)")
            }
            isGenerating = false
        }
    }
    
    private func copyLink() {
        if let link = generatedLink {
            UIPasteboard.general.string = link
            withAnimation {
                showCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showCopied = false
                }
            }
        }
    }
}
