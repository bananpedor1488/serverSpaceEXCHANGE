package com.bananjemmy.data.cache

import android.content.Context
import android.content.SharedPreferences

class PinnedChatsManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "pinned_chats_prefs",
        Context.MODE_PRIVATE
    )
    
    companion object {
        private const val KEY_PINNED_CHATS = "pinned_chats"
    }
    
    fun isPinned(chatId: String): Boolean {
        val pinnedChats = getPinnedChats()
        return pinnedChats.contains(chatId)
    }
    
    fun setPinned(chatId: String, isPinned: Boolean) {
        val pinnedChats = getPinnedChats().toMutableSet()
        if (isPinned) {
            pinnedChats.add(chatId)
        } else {
            pinnedChats.remove(chatId)
        }
        savePinnedChats(pinnedChats)
    }
    
    fun getPinnedChats(): Set<String> {
        val pinnedString = prefs.getString(KEY_PINNED_CHATS, "") ?: ""
        return if (pinnedString.isEmpty()) {
            emptySet()
        } else {
            pinnedString.split(",").toSet()
        }
    }
    
    private fun savePinnedChats(pinnedChats: Set<String>) {
        prefs.edit()
            .putString(KEY_PINNED_CHATS, pinnedChats.joinToString(","))
            .apply()
    }
    
    fun clear() {
        prefs.edit().clear().apply()
    }
}
