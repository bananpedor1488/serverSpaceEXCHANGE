import SwiftUI

struct SearchView: View {
    @State private var searchUsername = ""
    @State private var foundIdentity: Identity?
    @State private var isSearching = false
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Найти по username")
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
                VStack(spacing: 24) {
                    // Search field
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Введи username", text: $searchUsername)
                            .textFieldStyle(.plain)
                            .font(.system(size: 17))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        if !searchUsername.isEmpty {
                            Button(action: { searchUsername = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Button(action: searchByUsername) {
                        HStack(spacing: 8) {
                            if isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Найти")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: 300)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(searchUsername.isEmpty || isSearching)
                    
                    if let identity = foundIdentity {
                        VStack(spacing: 20) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(String(identity.username.prefix(2)).uppercased())
                                        .font(.system(size: 32, weight: .semibold))
                                )
                            
                            VStack(spacing: 8) {
                                Text(identity.username)
                                    .font(.system(size: 22, weight: .semibold))
                            }
                            
                            if !identity.bio.isEmpty {
                                Text(identity.bio)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            
                            Button(action: {}) {
                                Text("Начать чат")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: 300)
                                    .padding(.vertical, 12)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                }
            }
        }
        .alert("Не найдено", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Пользователь с username \(searchUsername) не найден")
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
}
