import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username: String
    @State private var tag: String
    @State private var bio: String
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(identity: Identity) {
        _username = State(initialValue: identity.username)
        _tag = State(initialValue: identity.tag)
        _bio = State(initialValue: identity.bio)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Отмена")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("Редактировать")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: saveProfile) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Готово")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isSaving || !isValid)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(username.prefix(2)).uppercased())
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                            .padding(.top, 32)
                        
                        // Username field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Имя")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 20)
                            
                            TextField("Имя пользователя", text: $username)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                        }
                        
                        // Tag field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Тег")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 20)
                            
                            HStack {
                                Text("#")
                                    .font(.system(size: 17, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                TextField("ABC123", text: $tag)
                                    .font(.system(size: 17, design: .monospaced))
                                    .foregroundColor(.white)
                                    .textInputAutocapitalization(.characters)
                                    .onChange(of: tag) { _, newValue in
                                        // Only allow alphanumeric characters
                                        let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                        if filtered != newValue {
                                            tag = filtered
                                        }
                                    }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            
                            if !tag.isEmpty && tag.count < 6 {
                                Text("Тег должен содержать 6 символов")
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        // Bio field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("О себе")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 20)
                            
                            TextEditor(text: $bio)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                                .scrollContentBackground(.hidden)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .alert("Ошибка", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValid: Bool {
        !username.isEmpty && tag.count == 6
    }
    
    private func saveProfile() {
        guard let identityId = authViewModel.identity?.id else { return }
        guard isValid else { return }
        
        isSaving = true
        Task {
            do {
                let url = URL(string: "https://weeky-six.vercel.app/api/identity/update")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "identity_id": identityId,
                    "username": username,
                    "tag": tag,
                    "bio": bio
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let updatedIdentity = try JSONDecoder().decode(Identity.self, from: data)
                    
                    await MainActor.run {
                        authViewModel.identity = updatedIdentity
                        dismiss()
                    }
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Не удалось сохранить изменения"])
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Не удалось сохранить. Возможно, тег уже занят."
                    showError = true
                }
            }
            await MainActor.run {
                isSaving = false
            }
        }
    }
}
