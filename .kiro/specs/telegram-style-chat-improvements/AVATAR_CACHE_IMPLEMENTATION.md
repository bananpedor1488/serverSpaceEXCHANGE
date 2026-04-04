# Avatar Caching System - Implementation Status

## ✅ COMPLETED

### 1. Backend (server.js)
- ✅ Added `avatar_updated_at` field to Identity schema
- ✅ `/api/identity/upload-avatar` endpoint sets `avatar_updated_at` timestamp
- ✅ Avatar stored as base64 in MongoDB

### 2. Android Implementation
- ✅ Added `avatarUpdatedAt` field to Identity model
- ✅ CacheManager avatar functions:
  - `saveAvatar(userId, base64, updatedAt)` - saves to SharedPreferences
  - `getAvatar(userId)` - returns Pair<String?, Long>?
  - `getAvatarCacheSize()` - calculates total size
  - `getAvatarCount()` - counts cached avatars
  - `clearAvatarCache()` - clears all avatars
  - `clearAvatar(userId)` - clears specific avatar
  - `base64ToBitmap(base64)` - converts base64 to Bitmap
- ✅ DataStorageScreen "Фото" section:
  - Shows avatar count and size
  - "Очистить аватары" button
  - Confirmation dialog
- ✅ MainActivity updated to pass avatar cache parameters

### 3. iOS Implementation
- ✅ Added `avatarUpdatedAt` field to Identity model
- ✅ CacheManager avatar functions:
  - `saveAvatar(userId:base64:updatedAt:)` - saves to UserDefaults
  - `getAvatar(userId:)` - returns (avatar: String, updatedAt: Int64)?
  - `getAvatarCacheSize()` - calculates total size
  - `getAvatarCount()` - counts cached avatars
  - `clearAvatarCache()` - clears all avatars
  - `clearAvatar(userId:)` - clears specific avatar
  - `base64ToImage(_:)` - converts base64 to UIImage

## 🔨 TODO - Avatar Loading Logic

### Android
Need to implement avatar loading with cache check in profile screens:

```kotlin
// In ProfileScreen, ContactProfileScreen, etc.
fun loadAvatar(userId: String, serverUpdatedAt: Long?) {
    // 1. Check cache first
    val cached = cacheManager.getAvatar(userId)
    
    if (cached != null) {
        val (cachedAvatar, cachedUpdatedAt) = cached
        
        // 2. Compare timestamps
        if (serverUpdatedAt == null || cachedUpdatedAt >= serverUpdatedAt) {
            // Use cached avatar
            val bitmap = cacheManager.base64ToBitmap(cachedAvatar)
            // Display bitmap
            Log.d("AVATAR", "loaded from cache")
            return
        }
    }
    
    // 3. Download from server if needed
    scope.launch {
        try {
            val identity = apiService.getIdentity(userId)
            if (identity.avatar != null && identity.avatarUpdatedAt != null) {
                cacheManager.saveAvatar(userId, identity.avatar, identity.avatarUpdatedAt)
                val bitmap = cacheManager.base64ToBitmap(identity.avatar)
                // Display bitmap
                Log.d("AVATAR", "updated from server")
            }
        } catch (e: Exception) {
            Log.e("AVATAR", "Failed to load avatar: ${e.message}")
        }
    }
}
```

### iOS
Need to implement avatar loading with cache check:

```swift
// In ProfileView, ContactProfileView, etc.
func loadAvatar(userId: String, serverUpdatedAt: Int64?) {
    // 1. Check cache first
    if let cached = CacheManager.shared.getAvatar(userId: userId) {
        // 2. Compare timestamps
        if serverUpdatedAt == nil || cached.updatedAt >= serverUpdatedAt! {
            // Use cached avatar
            if let image = CacheManager.shared.base64ToImage(cached.avatar) {
                self.avatarImage = image
                print("AVATAR: loaded from cache")
                return
            }
        }
    }
    
    // 3. Download from server if needed
    Task {
        do {
            let identity = try await APIService.shared.getIdentity(userId: userId)
            if let avatar = identity.avatar, let updatedAt = identity.avatarUpdatedAt {
                CacheManager.shared.saveAvatar(userId: userId, base64: avatar, updatedAt: updatedAt)
                if let image = CacheManager.shared.base64ToImage(avatar) {
                    self.avatarImage = image
                    print("AVATAR: updated from server")
                }
            }
        } catch {
            print("AVATAR: Failed to load - \(error)")
        }
    }
}
```

## 🔨 TODO - Avatar Upload UI

### Android
Need to add avatar upload in ProfileEditScreen:

```kotlin
// Add image picker
val launcher = rememberLauncherForActivityResult(
    contract = ActivityResultContracts.GetContent()
) { uri: Uri? ->
    uri?.let {
        // Convert to base64
        val bitmap = MediaStore.Images.Media.getBitmap(context.contentResolver, it)
        val base64 = bitmapToBase64(bitmap)
        
        // Upload to server
        scope.launch {
            try {
                val response = apiService.updateIdentity(
                    identityId,
                    UpdateIdentityRequest(avatar = base64)
                )
                // Save to cache
                response.body()?.let { identity ->
                    if (identity.avatar != null && identity.avatarUpdatedAt != null) {
                        cacheManager.saveAvatar(identityId, identity.avatar, identity.avatarUpdatedAt)
                    }
                }
            } catch (e: Exception) {
                Log.e("AVATAR", "Upload failed: ${e.message}")
            }
        }
    }
}

// Helper function
fun bitmapToBase64(bitmap: Bitmap): String {
    val outputStream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.JPEG, 80, outputStream)
    val bytes = outputStream.toByteArray()
    return Base64.encodeToString(bytes, Base64.DEFAULT)
}
```

### iOS
Need to add avatar upload in ProfileEditView:

```swift
// Add image picker
@State private var showImagePicker = false
@State private var selectedImage: UIImage?

// In body
Button("Изменить фото") {
    showImagePicker = true
}
.sheet(isPresented: $showImagePicker) {
    ImagePicker(image: $selectedImage)
}
.onChange(of: selectedImage) { image in
    guard let image = image else { return }
    uploadAvatar(image)
}

// Upload function
func uploadAvatar(_ image: UIImage) {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
    let base64 = imageData.base64EncodedString()
    
    Task {
        do {
            let identity = try await APIService.shared.updateIdentity(
                identityId: identityId,
                avatar: base64
            )
            
            if let avatar = identity.avatar, let updatedAt = identity.avatarUpdatedAt {
                CacheManager.shared.saveAvatar(userId: identityId, base64: avatar, updatedAt: updatedAt)
            }
        } catch {
            print("AVATAR: Upload failed - \(error)")
        }
    }
}
```

## 🔨 TODO - iOS DataStorageView

Need to create iOS equivalent of Android DataStorageScreen with "Фото" section showing:
- Avatar count
- Avatar cache size
- Clear avatars button

## ✅ BENEFITS

1. **Fast Loading**: Avatars load instantly from cache
2. **Reduced Traffic**: Only download when avatar changes
3. **Offline Support**: Cached avatars work without internet
4. **User Control**: Clear cache from settings
5. **Smart Updates**: Automatic check using `avatarUpdatedAt` timestamp

## 📊 CACHE STRUCTURE

### Android (SharedPreferences)
```
avatar_<userId> = "base64string..."
avatar_updated_<userId> = 1710000000
```

### iOS (UserDefaults)
```
avatar_<userId> = "base64string..."
avatar_updated_<userId> = 1710000000
```

## 🎯 NEXT STEPS

1. Implement avatar loading logic in profile screens (Android + iOS)
2. Add avatar upload UI (Android + iOS)
3. Create iOS DataStorageView with "Фото" section
4. Test avatar caching flow end-to-end
5. Test cache clearing functionality
