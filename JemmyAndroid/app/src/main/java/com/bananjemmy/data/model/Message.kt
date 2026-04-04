package com.bananjemmy.data.model

import com.google.gson.annotations.SerializedName

data class Message(
    @SerializedName("_id")
    val id: String,
    
    @SerializedName("chat_id")
    val chatId: String,
    
    @SerializedName("sender_identity_id")
    val senderId: String,
    
    @SerializedName("encrypted_content")
    val content: String,
    
    @SerializedName("createdAt")
    val createdAt: String,
    
    @SerializedName("client_time")
    val clientTime: Long? = null,
    
    @SerializedName("server_time")
    val serverTime: Long? = null,
    
    @SerializedName("delivered")
    val delivered: Boolean = false,
    
    @SerializedName("delivered_at")
    val deliveredAt: String? = null,
    
    @SerializedName("read")
    val read: Boolean = false,
    
    @SerializedName("read_at")
    val readAt: String? = null
) {
    // Используем serverTime если есть, иначе clientTime, иначе createdAt
    fun getDisplayTime(): Long {
        return serverTime ?: clientTime ?: run {
            // Парсим createdAt если нет других времен
            try {
                val formatter = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.getDefault())
                formatter.timeZone = java.util.TimeZone.getTimeZone("UTC")
                formatter.parse(createdAt)?.time ?: System.currentTimeMillis()
            } catch (e: Exception) {
                System.currentTimeMillis()
            }
        }
    }
}

data class SendMessageRequest(
    @SerializedName("chat_id")
    val chatId: String,
    
    @SerializedName("sender_identity_id")
    val senderIdentityId: String,
    
    @SerializedName("text")
    val text: String,
    
    @SerializedName("client_time")
    val clientTime: Long = System.currentTimeMillis()
)
