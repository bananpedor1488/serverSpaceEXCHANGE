package com.bananjemmy.data.cache.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "identities")
data class CachedIdentity(
    @PrimaryKey
    val id: String,
    val username: String,
    val bio: String,
    val updatedAt: Long = System.currentTimeMillis()
)
