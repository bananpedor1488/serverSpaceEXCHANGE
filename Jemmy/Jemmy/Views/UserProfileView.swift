import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    let user: Identity
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar & Info
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(String(user.username.prefix(2)).uppercased())
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(user.username)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("@\(user.username)")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                            
                            if !user.bio.isEmpty {
                                Text(user.bio)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .padding(.top, 24)
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            ActionButton(icon: "phone.fill", label: "Позвонить", color: .green)
                            ActionButton(icon: "video.fill", label: "Видео", color: .blue)
                            ActionButton(icon: "bell.fill", label: "Без звука", color: .purple)
                        }
                        .padding(.horizontal, 24)
                        
                        // Media Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Медиа")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("Все")
                                        .font(.system(size: 15))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Media Tabs
                            HStack(spacing: 0) {
                                MediaTabButton(title: "Фото", isSelected: selectedTab == 0) {
                                    selectedTab = 0
                                }
                                MediaTabButton(title: "Видео", isSelected: selectedTab == 1) {
                                    selectedTab = 1
                                }
                                MediaTabButton(title: "Файлы", isSelected: selectedTab == 2) {
                                    selectedTab = 2
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Media Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 2),
                                GridItem(.flexible(), spacing: 2),
                                GridItem(.flexible(), spacing: 2)
                            ], spacing: 2) {
                                ForEach(0..<6, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.white.opacity(0.3))
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                )
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct MediaTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
