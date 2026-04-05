package com.bananjemmy.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.PersonOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.Identity
import com.bananjemmy.data.repository.JemmyRepository
import com.bananjemmy.ui.components.AvatarImage
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BlockedUsersScreen(
    currentUserId: String,
    onBack: () -> Unit,
    cacheManager: com.bananjemmy.data.cache.CacheManager
) {
    val repository = remember { JemmyRepository() }
    var blockedUsers by remember { mutableStateOf<List<Identity>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var showUnblockDialog by remember { mutableStateOf(false) }
    var userToUnblock by remember { mutableStateOf<Identity?>(null) }
    val coroutineScope = rememberCoroutineScope()
    
    LaunchedEffect(Unit) {
        isLoading = true
        repository.getBlockedUsers(currentUserId).onSuccess { users ->
            blockedUsers = users
            isLoading = false
        }.onFailure {
            isLoading = false
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Заблокированные") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Назад")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when {
                isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                blockedUsers.isEmpty() -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.PersonOff,
                            contentDescription = null,
                            modifier = Modifier.size(60.dp),
                            tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                        )
                        Text(
                            text = "Нет заблокированных",
                            fontSize = 17.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(blockedUsers) { user ->
                            BlockedUserCard(
                                user = user,
                                cacheManager = cacheManager,
                                onUnblock = {
                                    userToUnblock = user
                                    showUnblockDialog = true
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    if (showUnblockDialog && userToUnblock != null) {
        AlertDialog(
            onDismissRequest = { showUnblockDialog = false },
            title = { Text("Разблокировать пользователя?") },
            text = { Text("Вы сможете снова получать сообщения от @${userToUnblock!!.username}") },
            confirmButton = {
                TextButton(
                    onClick = {
                        coroutineScope.launch {
                            repository.unblockUser(currentUserId, userToUnblock!!.id).onSuccess {
                                blockedUsers = blockedUsers.filter { it.id != userToUnblock!!.id }
                                showUnblockDialog = false
                                userToUnblock = null
                            }
                        }
                    }
                ) {
                    Text("Разблокировать")
                }
            },
            dismissButton = {
                TextButton(onClick = { showUnblockDialog = false }) {
                    Text("Отмена")
                }
            }
        )
    }
}

@Composable
fun BlockedUserCard(
    user: Identity,
    cacheManager: com.bananjemmy.data.cache.CacheManager,
    onUnblock: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            AvatarImage(
                identity = user,
                cacheManager = cacheManager,
                size = 56.dp
            )
            
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = user.username,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "@${user.username}",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
            
            Button(
                onClick = onUnblock,
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error.copy(alpha = 0.2f),
                    contentColor = MaterialTheme.colorScheme.error
                ),
                shape = RoundedCornerShape(8.dp)
            ) {
                Text("Разблокировать")
            }
        }
    }
}
