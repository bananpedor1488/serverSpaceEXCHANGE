package com.bananjemmy.data.model

import com.google.gson.annotations.SerializedName

data class PrivacySettings(
    @SerializedName("who_can_message")
    val whoCanMessage: String = "everyone",
    
    @SerializedName("who_can_see_profile")
    val whoCanSeeProfile: String = "everyone",
    
    @SerializedName("who_can_see_online")
    val whoCanSeeOnline: String = "everyone",
    
    @SerializedName("who_can_see_last_seen")
    val whoCanSeeLastSeen: String = "everyone",
    
    @SerializedName("auto_delete_messages")
    val autoDeleteMessages: Int = 0,
    
    @SerializedName("screenshot_protection")
    val screenshotProtection: Boolean = false
)

data class PrivacySettingsResponse(
    @SerializedName("privacy_settings")
    val privacySettings: PrivacySettings
)

data class UpdatePrivacySettingsRequest(
    @SerializedName("identity_id")
    val identityId: String,
    
    @SerializedName("settings")
    val settings: PrivacySettings
)

data class UpdatePrivacySettingsResponse(
    @SerializedName("success")
    val success: Boolean,
    
    @SerializedName("privacy_settings")
    val privacySettings: PrivacySettings
)
