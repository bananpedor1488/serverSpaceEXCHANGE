package com.bananjemmy.data.cache

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import android.util.Log
import com.bananjemmy.data.cache.entity.CachedChat
import com.bananjemmy.data.cache.entity.CachedIdentity
import com.bananjemmy.data.cache.entity.CachedMessage
import com.bananjemmy.data.model.Chat
import com.bananjemmy.data.model.Identity
import com.bananjemmy.data.model.Message
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.io.File

class CacheManager(context: Context) {
    private val database = JemmyDatabase.getDatabase(context)
    private val identityDao = database.identityDao()
    private val chatDao = database.chatDao()
    private val messageDao = database.messageDao()
    private val context = context.applicationContext
    
    init {
        Log.d("CACHE", "✅ CacheManager initialized")
    }
    
    // Identity Cache
    suspend fun cacheIdentity(identity: Identity) {
        val cached = CachedIdentity(
            id = identity.id,
            username = identity.username,
            bio = identity.bio
        )
        identityDao.insertIdentity(cached)
        Log.d("CACHE", "Cached identity: ${identity.username}")
    }
    
    suspend fun getCachedIdentity(identityId: String): Identity? {
        return identityDao.getIdentityById(identityId)?.let {
            Identity(
                username = it.username,
                bio = it.bio
            )
        }
    }
    
    // Chat Cache
    suspend fun cacheChats(chats: List<Chat>) {
        val cachedChats = chats.map { chat ->
            CachedChat(
                id = chat.id,
                userId = chat.user.id,
                username = chat.user.username,
                userBio = chat.user.bio,
                lastMessage = chat.lastMessage,
                lastMessageTime = chat.lastMessageTime,
                unreadCount = chat.unreadCount,
                isPinned = chat.isPinned,
                isMuted = chat.isMuted,
                updatedAt = System.currentTimeMillis()
            )
        }
        chatDao.insertChats(cachedChats)
        Log.d("CACHE", "Cached ${chats.size} chats")
    }
    
    suspend fun getCachedChats(): List<Chat> {
        val cached = chatDao.getAllChatsOnce()
        Log.d("CACHE", "📦 getCachedChats: Found ${cached.size} chats in database")
        val result = cached.map { it.toChat() }
        Log.d("CACHE", "📦 getCachedChats: Converted to ${result.size} Chat objects")
        return result
    }
    
    fun getCachedChatsFlow(): Flow<List<Chat>> {
        return chatDao.getAllChats().map { list ->
            list.map { it.toChat() }
        }
    }
    
    // Message Cache
    suspend fun cacheMessages(chatId: String, messages: List<Message>) {
        val cachedMessages = messages.map { message ->
            CachedMessage(
                id = message.id,
                chatId = chatId,
                senderId = message.senderId,
                content = message.content,
                createdAt = message.createdAt,
                updatedAt = System.currentTimeMillis()
            )
        }
        messageDao.insertMessages(cachedMessages)
        Log.d("CACHE", "Cached ${messages.size} messages for chat $chatId")
    }
    
    suspend fun cacheMessage(chatId: String, message: Message) {
        val cachedMessage = CachedMessage(
            id = message.id,
            chatId = chatId,
            senderId = message.senderId,
            content = message.content,
            createdAt = message.createdAt,
            updatedAt = System.currentTimeMillis()
        )
        messageDao.insertMessage(cachedMessage)
        Log.d("CACHE", "Cached message: ${message.id}")
    }
    
    suspend fun getCachedMessages(chatId: String): List<Message> {
        val cached = messageDao.getMessagesByChatIdOnce(chatId)
        Log.d("CACHE", "📦 getCachedMessages: Found ${cached.size} messages in database for chat $chatId")
        val result = cached.map { it.toMessage() }
        Log.d("CACHE", "📦 getCachedMessages: Converted to ${result.size} Message objects")
        return result
    }
    
    fun getCachedMessagesFlow(chatId: String): Flow<List<Message>> {
        return messageDao.getMessagesByChatId(chatId).map { list ->
            list.map { it.toMessage() }
        }
    }
    
    // Cache Stats
    suspend fun getCacheSize(): Long {
        val dbFile = context.getDatabasePath("jemmy_database")
        val dbDir = dbFile.parentFile
        
        Log.d("CACHE", "📊 Database path: ${dbFile.absolutePath}")
        
        var totalSize = 0L
        
        // Room создает несколько файлов: основной, -wal, -shm
        if (dbDir != null && dbDir.exists()) {
            dbDir.listFiles()?.forEach { file ->
                if (file.name.startsWith("jemmy_database")) {
                    val fileSize = file.length()
                    totalSize += fileSize
                    Log.d("CACHE", "📊 Found DB file: ${file.name}, size: $fileSize bytes")
                }
            }
        }
        
        // Добавляем размер аватарок
        val avatarSize = getAvatarCacheSize()
        totalSize += avatarSize
        
        Log.d("CACHE", "📊 Total database size: $totalSize bytes (${totalSize / 1024.0} KB) including avatars")
        
        return totalSize
    }
    
    suspend fun getCacheStats(): CacheStats {
        val chatsCount = chatDao.getChatsCount()
        val messagesCount = messageDao.getMessagesCount()
        val sizeBytes = getCacheSize()
        
        Log.d("CACHE", "📊 Cache stats - Chats: $chatsCount, Messages: $messagesCount, Size: $sizeBytes bytes")
        
        return CacheStats(
            chatsCount = chatsCount,
            messagesCount = messagesCount,
            sizeBytes = sizeBytes,
            sizeMB = sizeBytes / (1024.0 * 1024.0)
        )
    }
    
    // Clear Cache
    suspend fun clearAllCache() {
        try {
            chatDao.deleteAllChats()
            messageDao.deleteAllMessages()
            identityDao.deleteAllIdentities()
            
            // Очищаем аватарки
            clearAvatarCache()
            
            Log.d("CACHE", "Cleared all cache data (including avatars)")
            
            // Пытаемся сжать базу данных (может не сработать если база активна)
            try {
                database.openHelper.writableDatabase.execSQL("PRAGMA wal_checkpoint(FULL)")
                Log.d("CACHE", "WAL checkpoint completed")
            } catch (e: Exception) {
                Log.w("CACHE", "WAL checkpoint failed: ${e.message}")
            }
            
        } catch (e: Exception) {
            Log.e("CACHE", "Error clearing cache: ${e.message}", e)
            throw e
        }
    }
    
    suspend fun clearChatCache(chatId: String) {
        chatDao.deleteChat(chatId)
        messageDao.deleteMessagesByChatId(chatId)
        Log.d("CACHE", "Cleared cache for chat $chatId")
    }
    
    // Converters
    private fun CachedChat.toChat(): Chat {
        return Chat(
            id = this.id,
            user = Identity(
                _id = this.userId,
                username = this.username,
                bio = this.userBio
            ),
            lastMessage = this.lastMessage,
            lastMessageTime = this.lastMessageTime,
            unreadCount = this.unreadCount,
            isPinned = this.isPinned,
            isMuted = this.isMuted
        )
    }
    
    private fun CachedMessage.toMessage(): Message {
        return Message(
            id = this.id,
            chatId = this.chatId,
            senderId = this.senderId,
            content = this.content,
            createdAt = this.createdAt
        )
    }
    
    // Avatar Cache (using SharedPreferences for base64 strings)
    private val avatarPrefs = context.getSharedPreferences("avatar_cache", Context.MODE_PRIVATE)
    
    fun saveAvatar(userId: String, base64: String, updatedAt: Long) {
        avatarPrefs.edit().apply {
            putString("avatar_$userId", base64)
            putLong("avatar_updated_${userId}", updatedAt)
            apply()
        }
        Log.d("CACHE", "💾 Saved avatar for user $userId, updatedAt=$updatedAt")
    }
    
    fun getAvatar(userId: String): Pair<String?, Long>? {
        val avatar = avatarPrefs.getString("avatar_$userId", null)
        val updatedAt = avatarPrefs.getLong("avatar_updated_${userId}", 0)
        
        return if (avatar != null) {
            Log.d("CACHE", "📦 Loaded avatar from cache for user $userId")
            Pair(avatar, updatedAt)
        } else {
            Log.d("CACHE", "⚠️ No cached avatar for user $userId")
            null
        }
    }
    
    fun getAvatarCacheSize(): Long {
        var totalSize = 0L
        avatarPrefs.all.forEach { (key, value) ->
            if (key.startsWith("avatar_") && value is String) {
                totalSize += value.length
            }
        }
        Log.d("CACHE", "📊 Avatar cache size: $totalSize bytes (${totalSize / 1024.0} KB)")
        return totalSize
    }
    
    fun getAvatarCount(): Int {
        val count = avatarPrefs.all.count { it.key.startsWith("avatar_") && !it.key.contains("updated") }
        Log.d("CACHE", "📊 Cached avatars count: $count")
        return count
    }
    
    fun clearAvatarCache() {
        val keys = avatarPrefs.all.keys.filter { it.startsWith("avatar_") }
        avatarPrefs.edit().apply {
            keys.forEach { remove(it) }
            apply()
        }
        Log.d("CACHE", "🧹 Cleared avatar cache (${ keys.size / 2} avatars)")
    }
    
    fun clearAvatar(userId: String) {
        avatarPrefs.edit().apply {
            remove("avatar_$userId")
            remove("avatar_updated_${userId}")
            apply()
        }
        Log.d("CACHE", "🧹 Cleared avatar for user $userId")
    }
    
    // LastSeen Cache (using SharedPreferences)
    private val lastSeenPrefs = context.getSharedPreferences("last_seen_cache", Context.MODE_PRIVATE)
    
    fun saveLastSeen(userId: String, lastSeen: Long) {
        lastSeenPrefs.edit().apply {
            putLong("last_seen_$userId", lastSeen)
            apply()
        }
        Log.d("CACHE", "💾 Saved lastSeen for user $userId: $lastSeen")
    }
    
    fun getLastSeen(userId: String): Long? {
        val lastSeen = lastSeenPrefs.getLong("last_seen_$userId", -1)
        return if (lastSeen != -1L) {
            Log.d("CACHE", "📦 Loaded lastSeen from cache for user $userId: $lastSeen")
            lastSeen
        } else {
            Log.d("CACHE", "⚠️ No cached lastSeen for user $userId")
            null
        }
    }
    
    fun clearLastSeenCache() {
        val keys = lastSeenPrefs.all.keys.filter { it.startsWith("last_seen_") }
        lastSeenPrefs.edit().apply {
            keys.forEach { remove(it) }
            apply()
        }
        Log.d("CACHE", "🧹 Cleared lastSeen cache (${keys.size} entries)")
    }
    
    // Base64 to Bitmap conversion
    fun base64ToBitmap(base64: String): Bitmap? {
        return try {
            val bytes = Base64.decode(base64, Base64.DEFAULT)
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        } catch (e: Exception) {
            Log.e("CACHE", "❌ Failed to decode base64 to bitmap: ${e.message}")
            null
        }
    }
}

data class CacheStats(
    val chatsCount: Int,
    val messagesCount: Int,
    val sizeBytes: Long,
    val sizeMB: Double
)
