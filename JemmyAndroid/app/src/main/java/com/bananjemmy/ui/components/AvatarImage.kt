package com.bananjemmy.ui.components

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import android.util.Log
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.cache.CacheManager
import com.bananjemmy.data.model.Identity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun AvatarImage(
    identity: Identity,
    cacheManager: CacheManager,
    size: Dp = 48.dp,
    modifier: Modifier = Modifier
) {
    var bitmap by remember(identity.id, identity.avatarUpdatedAt) { mutableStateOf<Bitmap?>(null) }
    var isLoading by remember(identity.id, identity.avatarUpdatedAt) { mutableStateOf(true) }
    
    LaunchedEffect(identity.id, identity.avatarUpdatedAt) {
        isLoading = true
        bitmap = loadAvatar(identity, cacheManager)
        isLoading = false
    }
    
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.primaryContainer),
        contentAlignment = Alignment.Center
    ) {
        if (bitmap != null) {
            Image(
                bitmap = bitmap!!.asImageBitmap(),
                contentDescription = "Avatar",
                modifier = Modifier.size(size),
                contentScale = ContentScale.Crop
            )
        } else {
            // Default avatar - first letter of username
            Text(
                text = identity.username.firstOrNull()?.uppercase() ?: "?",
                fontSize = (size.value / 2).sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

private suspend fun loadAvatar(identity: Identity, cacheManager: CacheManager): Bitmap? {
    return withContext(Dispatchers.IO) {
        try {
            // Check if we have avatar data
            if (identity.avatar.isNullOrEmpty()) {
                Log.d("AVATAR", "❌ No avatar data for ${identity.username}")
                return@withContext null
            }
            
            val serverUpdatedAt = identity.avatarUpdatedAtLong ?: 0L
            
            // Check cache first
            val cached = cacheManager.getAvatar(identity.id)
            if (cached != null) {
                val (cachedBase64, cachedUpdatedAt) = cached
                
                // If cache is up to date, use it
                if (cachedUpdatedAt >= serverUpdatedAt) {
                    Log.d("AVATAR", "✅ Using cached avatar for ${identity.username}")
                    return@withContext base64ToBitmap(cachedBase64)
                } else {
                    Log.d("AVATAR", "⚠️ Cache outdated for ${identity.username} (cached: $cachedUpdatedAt, server: $serverUpdatedAt)")
                }
            }
            
            // Decode from server data
            Log.d("AVATAR", "📥 Decoding avatar from server for ${identity.username}")
            val bitmap = base64ToBitmap(identity.avatar!!)
            
            // Save to cache
            if (bitmap != null) {
                cacheManager.saveAvatar(identity.id, identity.avatar!!, serverUpdatedAt)
                Log.d("AVATAR", "💾 Saved avatar to cache for ${identity.username}")
            }
            
            bitmap
        } catch (e: Exception) {
            Log.e("AVATAR", "❌ Failed to load avatar for ${identity.username}: ${e.message}")
            null
        }
    }
}

private fun base64ToBitmap(base64: String): Bitmap? {
    return try {
        val bytes = Base64.decode(base64, Base64.DEFAULT)
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
    } catch (e: Exception) {
        Log.e("AVATAR", "❌ Failed to decode base64: ${e.message}")
        null
    }
}
