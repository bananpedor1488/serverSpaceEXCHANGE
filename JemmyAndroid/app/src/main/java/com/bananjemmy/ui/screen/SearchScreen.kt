package com.bananjemmy.ui.screen

import androidx.compose.animation.*
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.Identity
import kotlinx.coroutines.launch
import com.bananjemmy.ui.components.AvatarImage
import com.bananjemmy.data.cache.CacheManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    onSearch: suspend (String) -> Result<List<Identity>>,
    onStartChat: suspend (Identity) -> Result<String>,
    onDismiss: () -> Unit,
    onChatCreated: (String) -> Unit,
    cacheManager: CacheManager
) {
    var searchQuery by remember { mutableStateOf("") }
    var foundIdentities by remember { mutableStateOf<List<Identity>>(emptyList()) }
    var isSearching by remember { mutableStateOf(false) }
    var creatingChatForId by remember { mutableStateOf<String?>(null) }
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
                    if (it.isEmpty()) foundIdentities = emptyList()
                },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Введите username (с @ или без)") },
                leadingIcon = {
                    Icon(Icons.Filled.Search, null)
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { 
                            searchQuery = ""
                            foundIdentities = emptyList()
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
                        foundIdentities = emptyList()
                        coroutineScope.launch {
                            val result = onSearch(searchQuery.trim())
                            result.onSuccess { identities ->
                                if (identities.isEmpty()) {
                                    errorMessage = "Пользователи не найдены"
                                } else {
                                    foundIdentities = identities
                                }
                            }.onFailure {
                                errorMessage = "Ошибка поиска"
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
            
            // Found users list
            AnimatedVisibility(
                visible = foundIdentities.isNotEmpty(),
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(foundIdentities) { identity ->
                        UserSearchResultCard(
                            identity = identity,
                            cacheManager = cacheManager,
                            isCreatingChat = creatingChatForId == identity.id,
                            onClick = {
                                creatingChatForId = identity.id
                                coroutineScope.launch {
                                    val result = onStartChat(identity)
                                    result.onSuccess { chatId ->
                                        onChatCreated(chatId)
                                        // Don't call onDismiss here - let MainActivity handle it
                                    }.onFailure {
                                        errorMessage = "Не удалось создать чат"
                                        creatingChatForId = null
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun UserSearchResultCard(
    identity: Identity,
    cacheManager: CacheManager,
    isCreatingChat: Boolean,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = !isCreatingChat, onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            AvatarImage(
                identity = identity,
                cacheManager = cacheManager,
                size = 48.dp
            )
            
            // Username and bio
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = "@${identity.username}",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium
                )
                
                if (identity.bio.isNotEmpty()) {
                    Text(
                        text = identity.bio,
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1
                    )
                }
            }
            
            if (isCreatingChat) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp
                )
            } else {
                Icon(
                    imageVector = Icons.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
