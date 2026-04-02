import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    let user: Identity
    
    @State private var selectedTab = 0
    @State private var showDevices = false
    
    var body: some View {
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
                    
                    // Settings Section
                    VStack(spacing: 0) {
                        SettingsButton(
                            icon: "laptopcomputer.and.iphone",
                            title: "Устройства",
                            action: { showDevices = true }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 60)
                        
                        SettingsButton(
                            icon: "lock.fill",
                            title: "Конфиденциальность",
                            action: {}
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 60)
                        
                        SettingsButton(
                            icon: "bell.fill",
                            title: "Уведомления",
                            action: {}
                        )
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
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
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 0
                                }
                            }
                            MediaTabButton(title: "Видео", isSelected: selectedTab == 1) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 1
                                }
                            }
                            MediaTabButton(title: "Файлы", isSelected: selectedTab == 2) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = 2
                                }
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
            // Devices Sheet
            if showDevices {
                DevicesSheet(isPresented: $showDevices)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
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
        .animation(.easeInOut(duration: 0.3), value: showDevices)
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

struct SettingsButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

struct DevicesSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Header
                HStack {
                    Text("Устройства")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 12) {
                        DeviceRow(
                            icon: "iphone",
                            name: "iPhone 15 Pro",
                            info: "Это устройство",
                            isActive: true
                        )
                        
                        DeviceRow(
                            icon: "laptopcomputer",
                            name: "MacBook Pro",
                            info: "Активен 2 часа назад",
                            isActive: false
                        )
                        
                        DeviceRow(
                            icon: "ipad",
                            name: "iPad Air",
                            info: "Активен вчера",
                            isActive: false
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .background(
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
        )
    }
}

struct DeviceRow: View {
    let icon: String
    let name: String
    let info: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    if isActive {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(info)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            if !isActive {
                Button(action: {}) {
                    Text("Завершить")
                        .font(.system(size: 15))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
