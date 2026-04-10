package com.bananjemmy.data.model

import kotlinx.serialization.Serializable

@Serializable
data class Device(
    val id: String,
    val identityId: String,
    val deviceName: String,
    val deviceModel: String,
    val platform: String, // "android", "ios", "macos"
    val osVersion: String,
    val appVersion: String,
    val lastActive: Long,
    val isCurrent: Boolean = false
)

@Serializable
data class DevicesResponse(
    val devices: List<Device>
)

@Serializable
data class RegisterDeviceRequest(
    val identityId: String,
    val deviceName: String,
    val deviceModel: String,
    val platform: String,
    val osVersion: String,
    val appVersion: String
)

@Serializable
data class LogoutDeviceRequest(
    val identityId: String,
    val deviceId: String
)
