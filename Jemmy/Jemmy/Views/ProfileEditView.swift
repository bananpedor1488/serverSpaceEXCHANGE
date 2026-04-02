import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username: String
    @State private var bio: String
    @State private var isSaving = false
    
    init(identity: Identity) {
        _username = State(initialValue: identity.username)
        _bio = State(initialValue: identity.bio)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Имя") {
                    TextField("Username", text: $username)
                        .font(.system(size: 17, design: .rounded))
                }
                
                Section("О себе") {
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .font(.system(size: 15))
                }
                
                Section {
                    Button(action: saveProfile) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Сохранить")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        guard let identityId = authViewModel.identity?.id else { return }
        
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
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let updatedIdentity = try JSONDecoder().decode(Identity.self, from: data)
                
                await MainActor.run {
                    authViewModel.identity = updatedIdentity
                    dismiss()
                }
            } catch {
                print("Save error: \(error)")
            }
            isSaving = false
        }
    }
}
