package com.bananjemmy.data.cache.dao

import androidx.room.*
import com.bananjemmy.data.cache.entity.CachedChat
import kotlinx.coroutines.flow.Flow

@Dao
interface ChatDao {
    @Query("SELECT * FROM chats ORDER BY updatedAt DESC")
    fun getAllChats(): Flow<List<CachedChat>>
    
    @Query("SELECT * FROM chats ORDER BY updatedAt DESC")
    suspend fun getAllChatsOnce(): List<CachedChat>
    
    @Query("SELECT * FROM chats WHERE id = :chatId")
    suspend fun getChatById(chatId: String): CachedChat?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertChat(chat: CachedChat)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertChats(chats: List<CachedChat>)
    
    @Query("DELETE FROM chats WHERE id = :chatId")
    suspend fun deleteChat(chatId: String)
    
    @Query("DELETE FROM chats")
    suspend fun deleteAllChats()
    
    @Query("SELECT COUNT(*) FROM chats")
    suspend fun getChatsCount(): Int
}
