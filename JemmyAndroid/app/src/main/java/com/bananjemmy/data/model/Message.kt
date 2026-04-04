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
    
    @SerializedName("delivered")
    val delivered: Boolean = false,
    
    @SerializedName("delivered_at")
    val deliveredAt: String? = null,
    
    @SerializedName("read")
    val read: Boolean = false,
    
    @SerializedName("read_at")
    val readAt: String? = null
)

data class SendMessageRequest(
    @SerializedName("chat_id")
    val chatId: String,
    
    @SerializedName("sender_identity_id")
    val senderIdentityId: String,
    
    @SerializedName("text")
    val text: String
)
