import SwiftUI

struct SearchView: View {
    @State private var searchTag = ""
    @State private var foundIdentity: Identity?
    @State private var isSearching = false
    @State private var showError = false
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
                    
                    Text("Найти по тегу")
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
                            
                            TextField("Введи тег (ABC123)", text: $searchTag)
                                .textInputAutocapitalization(.characters)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .onChange(of: searchTag) { _, newValue in
                                    searchTag = newValue.uppercased()
                                }
                            
                            if !searchTag.isEmpty {
                                Button(action: { searchTag = "" }) {
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
                        
                        Button(action: searchByTag) {
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
                        .disabled(searchTag.isEmpty || isSearching)
                        
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
                                    
                                    Text("#\(identity.tag)")
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                if !identity.bio.isEmpty {
                                    Text(identity.bio)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                                
                                Button(action: {}) {
                                    Text("Начать чат")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
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
            Text("Пользователь с тегом \(searchTag) не найден")
        }
    }
    
    private func searchByTag() {
        isSearching = true
        Task {
            do {
                let url = URL(string: "https://weeky-six.vercel.app/api/identity/search/\(searchTag)")!
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
