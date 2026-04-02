import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    let user: Identity
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar & Info
                    VStack(spacing: 10) {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(user.username.prefix(2)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(user.username)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("@\(user.username)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        if !user.bio.isEmpty {
                            Text(user.bio)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        ActionButton(icon: "phone.fill", label: "Позвонить", color: .green)
                        ActionButton(icon: "video.fill", label: "Видео", color: .blue)
                        ActionButton(icon: "bell.fill", label: "Без звука", color: .purple)
                    }
                    .padding(.horizontal, 20)
                    
                    // Media Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Медиа")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Все")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        
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
                        .padding(.horizontal, 20)
                        
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
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {}) {
                    Image(systemName: "ellipsis")
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
        VStack(spacing: 6) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                )
            
            Text(label)
                .font(.system(size: 11))
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
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
