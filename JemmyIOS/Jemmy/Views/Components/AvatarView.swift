import SwiftUI

struct AvatarView: View {
    let identity: Identity
    let size: CGFloat
    
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    
    init(identity: Identity, size: CGFloat = 48) {
        self.identity = identity
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: size, height: size)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Default avatar - first letter
                Text(identity.username.prefix(1).uppercased())
                    .font(.system(size: size / 2, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
        .task(id: identity.id + String(identity.avatarUpdatedAt ?? 0)) {
            await loadAvatar()
        }
    }
    
    private func loadAvatar() async {
        isLoading = true
        defer { isLoading = false }
        
        print("AVATAR: 🔍 Loading avatar for \(identity.username)")
        print("AVATAR:    avatar.isEmpty = \(identity.avatar.isEmpty)")
        print("AVATAR:    avatar length = \(identity.avatar.count)")
        print("AVATAR:    avatarUpdatedAt = \(identity.avatarUpdatedAt ?? 0)")
        
        // Check if we have avatar data
        guard !identity.avatar.isEmpty else {
            print("AVATAR: ❌ No avatar data for \(identity.username)")
            return
        }
        
        let avatarBase64 = identity.avatar
        
        let serverUpdatedAt = identity.avatarUpdatedAt ?? 0
        
        // Check cache first
        if let cached = CacheManager.shared.getAvatar(userId: identity.id) {
            let (cachedBase64, cachedUpdatedAt) = cached
            
            // If cache is up to date, use it
            if cachedUpdatedAt >= serverUpdatedAt {
                print("AVATAR: ✅ Using cached avatar for \(identity.username)")
                self.image = CacheManager.shared.base64ToImage(cachedBase64)
                return
            } else {
                print("AVATAR: ⚠️ Cache outdated for \(identity.username) (cached: \(cachedUpdatedAt), server: \(serverUpdatedAt))")
            }
        }
        
        // Decode from server data
        print("AVATAR: 📥 Decoding avatar from server for \(identity.username)")
        if let decodedImage = CacheManager.shared.base64ToImage(avatarBase64) {
            self.image = decodedImage
            print("AVATAR: ✅ Successfully decoded avatar, size: \(decodedImage.size)")
            
            // Save to cache
            CacheManager.shared.saveAvatar(userId: identity.id, base64: avatarBase64, updatedAt: serverUpdatedAt)
            print("AVATAR: 💾 Saved avatar to cache for \(identity.username)")
        } else {
            print("AVATAR: ❌ Failed to decode avatar for \(identity.username)")
        }
    }
}
