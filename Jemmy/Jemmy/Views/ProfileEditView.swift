import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username: String
    @State private var bio: String
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool? = nil
    
    init(identity: Identity) {
        _username = State(initialValue: identity.username)
        _bio = State(initialValue: identity.bio)
        print("✏️ ProfileEditView initialized")
        print("   Username: \(identity.username)")
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        print("❌ Edit cancelled")
                        dismiss()
                    }) {
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
                                .foregroundColor(isValid ? .white : .white.opacity(0.3))
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
                            Text("Username")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 20)
                            
                            HStack {
                                TextField("username", text: $username)
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .onChange(of: username) { _, newValue in
                                        print("📝 Username changed: \(newValue)")
                                        usernameAvailable = nil
                                        checkUsernameDebounced()
                                    }
                                
                                if isCheckingUsername {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else if let available = usernameAvailable {
                                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(available ? .green : .red)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            
                            if !APIService.shared.isValidUsername(username) && !username.isEmpty {
                                Text("4-16 символов: a-z, 0-9, _")
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.horizontal, 20)
                            } else if let available = usernameAvailable, !available {
                                Text("Username уже занят")
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
                                .onChange(of: bio) { _, newValue in
                                    print("📝 Bio changed: \(newValue)")
                                }
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
        .alert("Успешно", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Профиль обновлен")
        }
    }
    
    private var isValid: Bool {
        let valid = APIService.shared.isValidUsername(username) && (usernameAvailable ?? false || username == authViewModel.identity?.username)
        if !valid {
            print("⚠️ Form invalid: username=\(username), valid format=\(APIService.shared.isValidUsername(username)), available=\(usernameAvailable ?? false)")
        }
        return valid
    }
    
    private var checkUsernameTask: Task<Void, Never>?
    
    private func checkUsernameDebounced() {
        checkUsernameTask?.cancel()
        
        guard username != authViewModel.identity?.username else {
            usernameAvailable = true
            return
        }
        
        guard APIService.shared.isValidUsername(username) else {
            usernameAvailable = false
            return
        }
        
        checkUsernameTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce
            
            guard !Task.isCancelled else { return }
            
            await checkUsername()
        }
    }
    
    private func checkUsername() async {
        isCheckingUsername = true
        
        do {
            let available = try await APIService.shared.checkUsername(username: username)
            await MainActor.run {
                usernameAvailable = available
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
        guard isValid else {
            print("❌ Cannot save: form is invalid")
            return
        }
        
        print("💾 Saving profile...")
        print("   Username: \(username)")
        print("   Bio: \(bio)")
        
        isSaving = true
        
        Task {
            do {
                try await authViewModel.updateProfile(
                    username: username,
                    bio: bio
                )
                
                await MainActor.run {
                    print("✅ Profile saved successfully")
                    isSaving = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    print("❌ Save failed: \(error.localizedDescription)")
                    errorMessage = "Не удалось сохранить. Возможно, username уже занят."
                    showError = true
                    isSaving = false
                }
            }
        }
    }
}
