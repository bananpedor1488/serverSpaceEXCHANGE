package com.bananjemmy.data.cache.dao

import androidx.room.*
import com.bananjemmy.data.cache.entity.CachedMessage
import kotlinx.coroutines.flow.Flow

@Dao
interface MessageDao {
    @Query("SELECT * FROM messages WHERE chatId = :chatId ORDER BY createdAt ASC")
    fun getMessagesByChatId(chatId: String): Flow<List<CachedMessage>>
    
    @Query("SELECT * FROM messages WHERE chatId = :chatId ORDER BY createdAt ASC")
    suspend fun getMessagesByChatIdOnce(chatId: String): List<CachedMessage>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: CachedMessage)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessages(messages: List<CachedMessage>)
    
    @Query("DELETE FROM messages WHERE chatId = :chatId")
    suspend fun deleteMessagesByChatId(chatId: String)
    
    @Query("DELETE FROM messages")
    suspend fun deleteAllMessages()
    
    @Query("SELECT COUNT(*) FROM messages")
    suspend fun getMessagesCount(): Int
}
