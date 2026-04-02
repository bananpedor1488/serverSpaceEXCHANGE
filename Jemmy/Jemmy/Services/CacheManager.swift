import Foundation

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
    
    func getCacheSizeByCategory() -> (photos: Int64, videos: Int64, files: Int64, messages: Int64) {
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
        
        // Пока у нас только сообщения в кэше, остальное будет 0
        // В будущем можно добавить кэширование медиа
        return (photos: 0, videos: 0, files: 0, messages: messagesSize)
    }
}
