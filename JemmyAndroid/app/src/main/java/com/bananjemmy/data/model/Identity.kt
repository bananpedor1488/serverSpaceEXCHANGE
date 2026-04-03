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
    
    @SerializedName("createdAt")
    val createdAt: String? = null,
    
    @SerializedName("expiresAt")
    val expiresAt: String? = null
) {
    // Use _id if available, otherwise use id
    val id: String
        get() = _id ?: idField ?: ""
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

data class UpdateIdentityRequest(
    @SerializedName("username")
    val username: String? = null,
    
    @SerializedName("bio")
    val bio: String? = null,
    
    @SerializedName("avatar")
    val avatar: String? = null
)
