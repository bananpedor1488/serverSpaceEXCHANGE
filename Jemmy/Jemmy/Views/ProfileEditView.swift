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
    @State private var showSuccess = false
    
    init(identity: Identity) {
        _username = State(initialValue: identity.username)
        _tag = State(initialValue: identity.tag)
        _bio = State(initialValue: identity.bio)
        print("✏️ ProfileEditView initialized")
        print("   Username: \(identity.username)")
        print("   Tag: \(identity.tag)")
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
                                .onChange(of: username) { _, newValue in
                                    print("📝 Username changed: \(newValue)")
                                }
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
                                        let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                        if filtered != newValue {
                                            tag = filtered
                                        }
                                        print("📝 Tag changed: \(tag)")
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
        let valid = !username.isEmpty && tag.count == 6
        if !valid {
            print("⚠️ Form invalid: username=\(username.isEmpty ? "empty" : "ok"), tag=\(tag.count)/6")
        }
        return valid
    }
    
    private func saveProfile() {
        guard isValid else {
            print("❌ Cannot save: form is invalid")
            return
        }
        
        print("💾 Saving profile...")
        print("   Username: \(username)")
        print("   Tag: \(tag)")
        print("   Bio: \(bio)")
        
        isSaving = true
        
        Task {
            do {
                try await authViewModel.updateProfile(
                    username: username,
                    tag: tag,
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
                    errorMessage = "Не удалось сохранить. Возможно, тег уже занят."
                    showError = true
                    isSaving = false
                }
            }
        }
    }
}
