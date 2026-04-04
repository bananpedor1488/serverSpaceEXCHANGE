package com.bananjemmy.ui.screen

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.Identity
import kotlinx.coroutines.launch
import com.bananjemmy.ui.components.AvatarImage
import com.bananjemmy.data.cache.CacheManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    onSearch: suspend (String) -> Result<Identity>,
    onStartChat: suspend (Identity) -> Result<String>,
    onDismiss: () -> Unit,
    onChatCreated: (String) -> Unit,
    cacheManager: CacheManager
) {
    var searchQuery by remember { mutableStateOf("") }
    var foundIdentity by remember { mutableStateOf<Identity?>(null) }
    var isSearching by remember { mutableStateOf(false) }
    var isCreatingChat by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    val coroutineScope = rememberCoroutineScope()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        "Поиск пользователей",
                        fontWeight = FontWeight.SemiBold
                    ) 
                },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.ArrowBack, "Назад")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
        ) {
            Spacer(modifier = Modifier.height(16.dp))
            
            // Search field
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { 
                    searchQuery = it
                    errorMessage = null
                    if (it.isEmpty()) foundIdentity = null
                },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Введите username") },
                leadingIcon = {
                    Icon(Icons.Filled.Search, null)
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { 
                            searchQuery = ""
                            foundIdentity = null
                            errorMessage = null
                        }) {
                            Icon(Icons.Filled.Clear, "Очистить")
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(28.dp)
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Search button
            Button(
                onClick = {
                    if (searchQuery.isNotBlank()) {
                        isSearching = true
                        errorMessage = null
                        foundIdentity = null
                        coroutineScope.launch {
                            val result = onSearch(searchQuery.trim())
                            result.onSuccess { identity ->
                                foundIdentity = identity
                            }.onFailure {
                                errorMessage = "Пользователь не найден"
                            }
                            isSearching = false
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                enabled = searchQuery.isNotBlank() && !isSearching,
                shape = RoundedCornerShape(24.dp)
            ) {
                if (isSearching) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("Найти", fontSize = 16.sp)
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Error message
            AnimatedVisibility(
                visible = errorMessage != null,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Filled.Info,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onErrorContainer
                        )
                        Text(
                            text = errorMessage ?: "",
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            fontSize = 14.sp
                        )
                    }
                }
            }
            
            // Found user card
            AnimatedVisibility(
                visible = foundIdentity != null,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                foundIdentity?.let { identity ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(20.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            // Avatar
                            AvatarImage(
                                identity = identity,
                                cacheManager = cacheManager,
                                size = 72.dp
                            )
                            
                            // Username
                            Text(
                                text = "@${identity.username}",
                                fontSize = 20.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                            
                            // Bio
                            if (identity.bio.isNotEmpty()) {
                                Text(
                                    text = identity.bio,
                                    fontSize = 14.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    textAlign = TextAlign.Center,
                                    lineHeight = 20.sp
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(4.dp))
                            
                            // Start chat button
                            Button(
                                onClick = {
                                    isCreatingChat = true
                                    coroutineScope.launch {
                                        val result = onStartChat(identity)
                                        result.onSuccess { chatId ->
                                            onChatCreated(chatId)
                                            onDismiss()
                                        }.onFailure {
                                            errorMessage = "Не удалось создать чат"
                                        }
                                        isCreatingChat = false
                                    }
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(48.dp),
                                enabled = !isCreatingChat,
                                shape = RoundedCornerShape(24.dp)
                            ) {
                                if (isCreatingChat) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(24.dp),
                                        strokeWidth = 2.dp,
                                        color = MaterialTheme.colorScheme.onPrimary
                                    )
                                } else {
                                    Icon(
                                        Icons.Filled.Send,
                                        contentDescription = null,
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text("Начать чат", fontSize = 16.sp)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
