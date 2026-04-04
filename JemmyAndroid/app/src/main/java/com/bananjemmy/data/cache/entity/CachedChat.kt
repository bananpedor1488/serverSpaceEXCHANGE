package com.bananjemmy.data.cache.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "chats")
data class CachedChat(
    @PrimaryKey
    val id: String,
    val userId: String,
    val username: String,
    val userBio: String,
    val lastMessage: String,
    val lastMessageTime: String,
    val unreadCount: Int,
    val isPinned: Boolean,
    val isMuted: Boolean,
    val updatedAt: Long = System.currentTimeMillis()
)
