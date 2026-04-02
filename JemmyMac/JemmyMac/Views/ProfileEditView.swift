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
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Редактировать")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button(action: saveProfile) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Готово")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)
                .disabled(isSaving || !isValid)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(username.prefix(2)).uppercased())
                                .font(.system(size: 40, weight: .semibold))
                        )
                        .padding(.top, 32)
                    
                    // Username field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Имя")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("Имя пользователя", text: $username)
                            .textFieldStyle(.plain)
                            .font(.system(size: 17))
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 40)
                    
                    // Tag field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Тег")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("#")
                                .font(.system(size: 17, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            TextField("ABC123", text: $tag)
                                .textFieldStyle(.plain)
                                .font(.system(size: 17, design: .monospaced))
                                .onChange(of: tag) { _, newValue in
                                    let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                    if filtered != newValue {
                                        tag = filtered
                                    }
                                }
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        if !tag.isEmpty && tag.count < 6 {
                            Text("Тег должен содержать 6 символов")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Bio field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("О себе")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $bio)
                            .font(.system(size: 15))
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
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
