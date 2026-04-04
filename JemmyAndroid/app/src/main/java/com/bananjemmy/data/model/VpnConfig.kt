package com.bananjemmy.data.model

import kotlinx.serialization.Serializable

@Serializable
data class VpnConfig(
    val id: String,
    val name: String,
    val vlessUrl: String,
    val createdAt: Long = System.currentTimeMillis(),
    val lastPingTime: Long = 0,
    val lastPingLatency: Long = 0,
    val isReachable: Boolean = false
)
