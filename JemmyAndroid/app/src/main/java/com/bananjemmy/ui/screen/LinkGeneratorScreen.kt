package com.bananjemmy.ui.screen

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LinkGeneratorScreen(
    identityId: String,
    onGenerateLink: suspend () -> Result<String>,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    var generatedLink by remember { mutableStateOf<String?>(null) }
    var linkExpiresAt by remember { mutableStateOf<Date?>(null) }
    var isGenerating by remember { mutableStateOf(false) }
    var showCopied by remember { mutableStateOf(false) }
    
    // Load saved link
    LaunchedEffect(identityId) {
        val prefs = context.getSharedPreferences("invite_links", Context.MODE_PRIVATE)
        val savedLink = prefs.getString("link_$identityId", null)
        val expiryTimestamp = prefs.getLong("expiry_$identityId", 0)
        
        if (savedLink != null && expiryTimestamp > System.currentTimeMillis()) {
            generatedLink = savedLink
            linkExpiresAt = Date(expiryTimestamp)
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Создать ссылку") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = "Закрыть")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(40.dp))
            
            // Icon
            Surface(
                modifier = Modifier.size(100.dp),
                shape = CircleShape,
                color = MaterialTheme.colorScheme.primaryContainer
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Filled.Share,
                        contentDescription = null,
                        modifier = Modifier.size(50.dp),
                        tint = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            
            Text(
                text = "Одноразовая ссылка",
                fontSize = 24.sp,
                fontWeight = FontWeight.SemiBold
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "Создай ссылку для начала чата.\nОна действует 24 часа.",
                fontSize = 15.sp,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            if (generatedLink != null && linkExpiresAt != null) {
                // Show generated link
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Expiry timer
                    Surface(
                        color = MaterialTheme.colorScheme.errorContainer,
                        shape = MaterialTheme.shapes.small
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Info,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.onErrorContainer
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = formatTimeRemaining(linkExpiresAt!!),
                                fontSize = 14.sp,
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Link text
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        shape = MaterialTheme.shapes.medium
                    ) {
                        Text(
                            text = generatedLink!!,
                            modifier = Modifier.padding(16.dp),
                            fontSize = 13.sp,
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Copy button
                    Button(
                        onClick = {
                            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                            val clip = ClipData.newPlainText("invite_link", generatedLink)
                            clipboard.setPrimaryClip(clip)
                            showCopied = true
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = if (showCopied) Icons.Filled.Check else Icons.Filled.Send,
                            contentDescription = null
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(if (showCopied) "Скопировано" else "Копировать")
                    }
                    
                    LaunchedEffect(showCopied) {
                        if (showCopied) {
                            delay(2000)
                            showCopied = false
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    TextButton(
                        onClick = {
                            // Clear saved link
                            val prefs = context.getSharedPreferences("invite_links", Context.MODE_PRIVATE)
                            prefs.edit()
                                .remove("link_$identityId")
                                .remove("expiry_$identityId")
                                .apply()
                            generatedLink = null
                            linkExpiresAt = null
                        }
                    ) {
                        Text("Создать новую ссылку")
                    }
                }
            } else {
                // Generate button
                val coroutineScope = rememberCoroutineScope()
                Button(
                    onClick = {
                        isGenerating = true
                        coroutineScope.launch {
                            val result = onGenerateLink()
                            result.onSuccess { link ->
                                val expiryDate = Date(System.currentTimeMillis() + 24 * 60 * 60 * 1000)
                                
                                // Save link
                                val prefs = context.getSharedPreferences("invite_links", Context.MODE_PRIVATE)
                                prefs.edit()
                                    .putString("link_$identityId", link)
                                    .putLong("expiry_$identityId", expiryDate.time)
                                    .apply()
                                
                                generatedLink = link
                                linkExpiresAt = expiryDate
                            }
                            isGenerating = false
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isGenerating
                ) {
                    if (isGenerating) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Icon(Icons.Filled.Add, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Создать ссылку")
                    }
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

private fun formatTimeRemaining(expiryDate: Date): String {
    val now = System.currentTimeMillis()
    val diff = expiryDate.time - now
    
    val hours = (diff / (1000 * 60 * 60)).toInt()
    val minutes = ((diff % (1000 * 60 * 60)) / (1000 * 60)).toInt()
    
    return when {
        hours > 0 -> "Осталось ${hours}ч ${minutes}м"
        minutes > 0 -> "Осталось ${minutes}м"
        else -> "Истекла"
    }
}
