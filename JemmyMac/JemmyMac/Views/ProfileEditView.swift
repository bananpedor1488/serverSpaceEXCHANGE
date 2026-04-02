import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username: String
    @State private var bio: String
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool? = nil
    @State private var checkUsernameTask: Task<Void, Never>?
    
    init(identity: Identity) {
        _username = State(initialValue: identity.username)
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
                        Text("Username")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("username", text: $username)
                                .textFieldStyle(.plain)
                                .font(.system(size: 17))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: username) { _, newValue in
                                    usernameAvailable = nil
                                    checkUsernameDebounced()
                                }
                            
                            if isCheckingUsername {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let available = usernameAvailable {
                                Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(available ? .green : .red)
                            }
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        if !username.isEmpty && (username.count < 4 || username.count > 16) {
                            Text("4-16 символов: a-z, 0-9, _")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        } else if let available = usernameAvailable, !available {
                            Text("Username уже занят")
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
        let regex = "^[a-zA-Z0-9_]{4,16}$"
        let valid = username.range(of: regex, options: .regularExpression) != nil && (usernameAvailable ?? false || username == authViewModel.identity?.username)
        return valid
    }
    
    private func checkUsernameDebounced() {
        checkUsernameTask?.cancel()
        
        guard username != authViewModel.identity?.username else {
            usernameAvailable = true
            return
        }
        
        let regex = "^[a-zA-Z0-9_]{4,16}$"
        guard username.range(of: regex, options: .regularExpression) != nil else {
            usernameAvailable = false
            return
        }
        
        checkUsernameTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else { return }
            
            await checkUsername()
        }
    }
    
    private func checkUsername() async {
        isCheckingUsername = true
        
        do {
            let url = URL(string: "https://weeky-six.vercel.app/api/identity/check-username/\(username)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode([String: Bool].self, from: data)
            
            await MainActor.run {
                usernameAvailable = response["available"] ?? false
                isCheckingUsername = false
            }
        } catch {
            await MainActor.run {
                usernameAvailable = false
                isCheckingUsername = false
            }
        }
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
                    errorMessage = "Не удалось сохранить. Возможно, username уже занят."
                    showError = true
                }
            }
            await MainActor.run {
                isSaving = false
            }
        }
    }
}
