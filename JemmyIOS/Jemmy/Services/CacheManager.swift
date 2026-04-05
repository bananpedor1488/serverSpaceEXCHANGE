import Foundation
import UIKit

class CacheManager {
    static let shared = CacheManager()
    
    private let chatsKey = "cached_chats"
    private let messagesPrefix = "cached_messages_"
    
    private init() {}
    
    // MARK: - Chats
    
    func saveChats(_ chats: [ChatListItem]) {
        do {
            let data = try JSONEncoder().encode(chats)
            UserDefaults.standard.set(data, forKey: chatsKey)
            print("💾 Chats cached: \(chats.count)")
        } catch {
            print("❌ Cache save error:", error.localizedDescription)
        }
    }
    
    func loadChats() -> [ChatListItem]? {
        guard let data = UserDefaults.standard.data(forKey: chatsKey) else {
            print("⚠️ No cached chats")
            return nil
        }
        
        do {
            let chats = try JSONDecoder().decode([ChatListItem].self, from: data)
            print("📦 Loaded cached chats: \(chats.count)")
            return chats
        } catch {
            print("❌ Cache load error:", error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Messages
    
    func saveMessages(_ messages: [ChatMessage], chatId: String) {
        do {
            let data = try JSONEncoder().encode(messages)
            UserDefaults.standard.set(data, forKey: messagesPrefix + chatId)
            print("💾 Messages cached for chat \(chatId): \(messages.count)")
        } catch {
            print("❌ Cache save error:", error.localizedDescription)
        }
    }
    
    func loadMessages(chatId: String) -> [ChatMessage]? {
        guard let data = UserDefaults.standard.data(forKey: messagesPrefix + chatId) else {
            print("⚠️ No cached messages for chat \(chatId)")
            return nil
        }
        
        do {
            let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
            print("📦 Loaded cached messages: \(messages.count)")
            return messages
        } catch {
            print("❌ Cache load error:", error.localizedDescription)
            return nil
        }
    }
    
    func clearAll() {
        // Удаляем чаты
        UserDefaults.standard.removeObject(forKey: chatsKey)
        
        // Удаляем все сообщения
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(messagesPrefix) {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        print("🗑️ Cache cleared")
    }
    
    // MARK: - Cache Size
    
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        
        // Размер чатов
        if let data = UserDefaults.standard.data(forKey: chatsKey) {
            totalSize += Int64(data.count)
        }
        
        // Размер всех сообщений
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(messagesPrefix) {
                if let data = UserDefaults.standard.data(forKey: key) {
                    totalSize += Int64(data.count)
                }
            }
        }
        
        print("📊 Total cache size: \(totalSize) bytes")
        return totalSize
    }
    
    func getCacheSizeByCategory() -> (photos: Int64, videos: Int64, files: Int64, messages: Int64, avatars: Int64) {
        var messagesSize: Int64 = 0
        
        // Размер чатов
        if let data = UserDefaults.standard.data(forKey: chatsKey) {
            messagesSize += Int64(data.count)
        }
        
        // Размер всех сообщений
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(messagesPrefix) {
                if let data = UserDefaults.standard.data(forKey: key) {
                    messagesSize += Int64(data.count)
                }
            }
        }
        
        // Размер аватарок
        let avatarsSize = getAvatarCacheSize()
        
        // Пока у нас только сообщения и аватарки в кэше, остальное будет 0
        // В будущем можно добавить кэширование медиа
        return (photos: 0, videos: 0, files: 0, messages: messagesSize, avatars: avatarsSize)
    }
    
    // MARK: - Avatar Cache
    
    private let avatarPrefix = "avatar_"
    private let avatarUpdatedPrefix = "avatar_updated_"
    
    func saveAvatar(userId: String, base64: String, updatedAt: Int64) {
        UserDefaults.standard.set(base64, forKey: avatarPrefix + userId)
        UserDefaults.standard.set(updatedAt, forKey: avatarUpdatedPrefix + userId)
        print("💾 Saved avatar for user \(userId), updatedAt=\(updatedAt)")
    }
    
    func getAvatar(userId: String) -> (avatar: String, updatedAt: Int64)? {
        guard let avatar = UserDefaults.standard.string(forKey: avatarPrefix + userId) else {
            print("⚠️ No cached avatar for user \(userId)")
            return nil
        }
        
        let updatedAt = UserDefaults.standard.object(forKey: avatarUpdatedPrefix + userId) as? Int64 ?? 0
        print("📦 Loaded avatar from cache for user \(userId)")
        return (avatar, updatedAt)
    }
    
    func getAvatarCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        for key in allKeys {
            if key.hasPrefix(avatarPrefix) && !key.hasPrefix(avatarUpdatedPrefix) {
                if let avatar = UserDefaults.standard.string(forKey: key) {
                    totalSize += Int64(avatar.count)
                }
            }
        }
        
        print("📊 Avatar cache size: \(totalSize) bytes (\(Double(totalSize) / 1024.0) KB)")
        return totalSize
    }
    
    func getAvatarCount() -> Int {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let count = allKeys.filter { $0.hasPrefix(avatarPrefix) && !$0.hasPrefix(avatarUpdatedPrefix) }.count
        print("📊 Cached avatars count: \(count)")
        return count
    }
    
    func clearAvatarCache() {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let avatarKeys = allKeys.filter { $0.hasPrefix(avatarPrefix) }
        
        for key in avatarKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🧹 Cleared avatar cache (\(avatarKeys.count / 2) avatars)")
    }
    
    func clearAvatar(userId: String) {
        UserDefaults.standard.removeObject(forKey: avatarPrefix + userId)
        UserDefaults.standard.removeObject(forKey: avatarUpdatedPrefix + userId)
        print("🧹 Cleared avatar for user \(userId)")
    }
    
    // MARK: - Base64 to UIImage
    
    func base64ToImage(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64) else {
            print("❌ Failed to decode base64 string")
            return nil
        }
        return UIImage(data: data)
    }
    
    // MARK: - LastSeen Cache
    
    private let lastSeenPrefix = "last_seen_"
    
    func saveLastSeen(userId: String, lastSeen: Int64) {
        UserDefaults.standard.set(lastSeen, forKey: lastSeenPrefix + userId)
        print("💾 Saved lastSeen for user \(userId): \(lastSeen)")
    }
    
    func getLastSeen(userId: String) -> Int64? {
        let lastSeen = UserDefaults.standard.object(forKey: lastSeenPrefix + userId) as? Int64
        if let lastSeen = lastSeen {
            print("📦 Loaded lastSeen from cache for user \(userId): \(lastSeen)")
            return lastSeen
        } else {
            print("⚠️ No cached lastSeen for user \(userId)")
            return nil
        }
    }
    
    func clearLastSeenCache() {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let lastSeenKeys = allKeys.filter { $0.hasPrefix(lastSeenPrefix) }
        
        for key in lastSeenKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("🧹 Cleared lastSeen cache (\(lastSeenKeys.count) entries)")
    }
}
