package com.bananjemmy.data.model

import com.google.gson.annotations.SerializedName

data class Identity(
    @SerializedName("_id")
    val _id: String? = null,
    
    @SerializedName("id")
    val idField: String? = null,
    
    @SerializedName("username")
    val username: String,
    
    @SerializedName("bio")
    val bio: String = "",
    
    @SerializedName("avatar")
    val avatar: String? = null,
    
    @SerializedName("avatar_updated_at")
    val avatarUpdatedAt: String? = null,
    
    @SerializedName("createdAt")
    val createdAt: String? = null,
    
    @SerializedName("expiresAt")
    val expiresAtCamel: String? = null,
    
    @SerializedName("expires_at")
    val expiresAt: String? = null,
    
    @SerializedName("last_seen")
    val lastSeen: String? = null
) {
    // Use _id if available, otherwise use id
    val id: String
        get() = _id ?: idField ?: ""
    
    // Parse avatarUpdatedAt timestamp from string
    val avatarUpdatedAtLong: Long?
        get() = avatarUpdatedAt?.toLongOrNull()
}

data class CreateIdentityRequest(
    @SerializedName("device_id")
    val deviceId: String,
    
    @SerializedName("public_key")
    val publicKey: String
)

data class AuthResponse(
    @SerializedName("user_id")
    val userId: String,
    
    @SerializedName("identity")
    val identity: Identity
)

data class DeviceCheckResponse(
    @SerializedName("exists")
    val exists: Boolean,
    
    @SerializedName("identity")
    val identity: Identity? = null,
    
    @SerializedName("user_id")
    val userId: String? = null
)

data class UpdateIdentityRequest(
    @SerializedName("username")
    val username: String? = null,
    
    @SerializedName("bio")
    val bio: String? = null,
    
    @SerializedName("avatar")
    val avatar: String? = null
)

// Block/Unblock models
data class BlockUserRequest(
    @SerializedName("blocker_identity_id")
    val blockerIdentityId: String,
    
    @SerializedName("blocked_identity_id")
    val blockedIdentityId: String
)

data class BlockUserResponse(
    @SerializedName("success")
    val success: Boolean,
    
    @SerializedName("message")
    val message: String
)

data class UnblockUserRequest(
    @SerializedName("blocker_identity_id")
    val blockerIdentityId: String,
    
    @SerializedName("blocked_identity_id")
    val blockedIdentityId: String
)

data class UnblockUserResponse(
    @SerializedName("success")
    val success: Boolean,
    
    @SerializedName("message")
    val message: String
)

data class BlockedUsersResponse(
    @SerializedName("blocked_users")
    val blockedUsers: List<Identity>
)
