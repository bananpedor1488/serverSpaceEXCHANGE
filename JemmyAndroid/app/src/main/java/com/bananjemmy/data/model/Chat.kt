package com.bananjemmy.data.model

import com.google.gson.annotations.SerializedName

data class Chat(
    @SerializedName("id")
    val id: String,
    
    @SerializedName("lastMessage")
    val lastMessage: String = "",
    
    @SerializedName("lastMessageTime")
    val lastMessageTime: String = "",
    
    @SerializedName("user")
    val user: Identity,
    
    @SerializedName("is_pinned")
    val isPinned: Boolean = false,
    
    @SerializedName("unread_count")
    val unreadCount: Int = 0,
    
    @SerializedName("is_muted")
    val isMuted: Boolean = false,
    
    // Online status (not from API, managed locally)
    var isOnline: Boolean? = null,
    var lastSeen: Long? = null
)

data class CreateChatRequest(
    @SerializedName("participantId")
    val participantId: String
)

data class StartChatByTokenRequest(
    @SerializedName("token")
    val token: String
)

data class StartDirectChatRequest(
    @SerializedName("my_identity_id")
    val myIdentityId: String,
    
    @SerializedName("other_identity_id")
    val otherIdentityId: String
)

data class StartChatByInviteRequest(
    @SerializedName("token")
    val token: String,
    
    @SerializedName("my_identity_id")
    val myIdentityId: String
)

data class ChatStartResponse(
    @SerializedName("chat_id")
    val chatId: String,
    
    @SerializedName("other_user")
    val otherUser: Identity
)

data class InviteLinkPreview(
    @SerializedName("identity")
    val identity: Identity
)

data class GenerateInviteLinkRequest(
    @SerializedName("identity_id")
    val identityId: String
)

data class InviteLink(
    @SerializedName("url")
    val url: String
)

data class UsernameCheckResponse(
    @SerializedName("available")
    val available: Boolean
)

data class UpdateProfileRequest(
    @SerializedName("identity_id")
    val identityId: String,
    
    @SerializedName("username")
    val username: String? = null,
    
    @SerializedName("bio")
    val bio: String? = null
)
