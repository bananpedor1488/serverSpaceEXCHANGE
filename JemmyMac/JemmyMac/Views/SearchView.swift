import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var foundIdentity: Identity?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Поиск по username")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Введите username", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        search()
                    }
                
                if isSearching {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            // Results
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
                            .font(.system(size: 24, weight: .semibold))
                        
                        if !identity.bio.isEmpty {
                            Text(identity.bio)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    Button(action: {
                        // TODO: Start chat
                    }) {
                        Text("Начать чат")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
                .padding()
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(error)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(width: 500, height: 600)
    }
    
    private func search() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        foundIdentity = nil
        
        Task {
            do {
                let identity = try await APIService.shared.searchByTag(tag: searchText)
                
                await MainActor.run {
                    foundIdentity = identity
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Пользователь не найден"
                    isSearching = false
                }
            }
        }
    }
}
