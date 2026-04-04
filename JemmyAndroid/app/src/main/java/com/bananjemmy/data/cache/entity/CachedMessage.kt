package com.bananjemmy.data.cache.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "messages")
data class CachedMessage(
    @PrimaryKey
    val id: String,
    val chatId: String,
    val senderId: String,
    val content: String,
    val createdAt: String,
    val updatedAt: Long = System.currentTimeMillis()
)
