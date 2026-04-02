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
        UserDefaults.standard.removeObject(forKey: chatsKey)
        print("🗑️ Cache cleared")
    }
}
