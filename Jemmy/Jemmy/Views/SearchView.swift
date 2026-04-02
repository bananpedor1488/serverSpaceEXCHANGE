import SwiftUI

struct SearchView: View {
    @State private var searchTag = ""
    @State private var foundIdentity: Identity?
    @State private var isSearching = false
    @State private var showError = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(colorScheme == .dark ? .black : .white)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Введи тег (ABC123)", text: $searchTag)
                            .textInputAutocapitalization(.characters)
                            .font(.system(size: 17, design: .rounded))
                            .onChange(of: searchTag) { _, newValue in
                                searchTag = newValue.uppercased()
                            }
                        
                        if !searchTag.isEmpty {
                            Button(action: { searchTag = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Button(action: searchByTag) {
                        HStack {
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
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(searchTag.isEmpty || isSearching)
                    
                    if let identity = foundIdentity {
                        VStack(spacing: 16) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(String(identity.username.prefix(2)))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(identity.username)
                                .font(.system(size: 24, weight: .semibold))
                            
                            Text("#\(identity.tag)")
                                .font(.system(size: 15, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            if !identity.bio.isEmpty {
                                Text(identity.bio)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            Button(action: {}) {
                                Text("Начать чат")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(20)
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Поиск")
            .alert("Не найдено", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Пользователь с тегом \(searchTag) не найден")
            }
        }
    }
    
    private func searchByTag() {
        isSearching = true
        Task {
            do {
                let url = URL(string: "https://weeky-six.vercel.app/api/identity/search/\(searchTag)")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let identity = try JSONDecoder().decode(Identity.self, from: data)
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    foundIdentity = identity
                }
            } catch {
                showError = true
                foundIdentity = nil
            }
            isSearching = false
        }
    }
}
