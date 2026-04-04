import Foundation

class PinnedChatsManager {
    static let shared = PinnedChatsManager()
    
    private let defaults = UserDefaults.standard
    private let pinnedChatsKey = "pinnedChats"
    
    private init() {}
    
    func isPinned(_ chatId: String) -> Bool {
        return getPinnedChats().contains(chatId)
    }
    
    func togglePin(_ chatId: String) {
        var pinnedChats = getPinnedChats()
        if pinnedChats.contains(chatId) {
            pinnedChats.remove(chatId)
        } else {
            pinnedChats.insert(chatId)
        }
        savePinnedChats(pinnedChats)
    }
    
    func getPinnedChats() -> Set<String> {
        if let array = defaults.array(forKey: pinnedChatsKey) as? [String] {
            return Set(array)
        }
        return []
    }
    
    private func savePinnedChats(_ chats: Set<String>) {
        defaults.set(Array(chats), forKey: pinnedChatsKey)
    }
}
