package com.bananjemmy.ui.screen

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.Identity
import com.bananjemmy.data.repository.JemmyRepository
import com.bananjemmy.ui.viewmodel.ChatViewModel
import com.bananjemmy.ui.components.AvatarImage
import com.bananjemmy.data.cache.CacheManager
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ContactProfileScreen(
    user: Identity,
    onDismiss: () -> Unit,
    chatViewModel: ChatViewModel,
    isOnline: Boolean = false,
    lastSeen: Long = 0,
    cacheManager: CacheManager,
    currentUserId: String
) {
    val repository = remember { JemmyRepository() }
    var selectedMediaTab by remember { mutableIntStateOf(0) }
    var isBlocked by remember { mutableStateOf(false) }
    var amIBlocked by remember { mutableStateOf(false) }
    var showBlockDialog by remember { mutableStateOf(false) }
    var showUnblockDialog by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()
    
    // Check if user is blocked
    LaunchedEffect(Unit) {
        repository.getBlockedUsers(currentUserId).onSuccess { blockedUsers ->
            isBlocked = blockedUsers.any { it.id == user.id }
        }
        
        // Check if I am blocked by this user
        repository.amIBlockedBy(currentUserId, user.id).onSuccess { blocked ->
            amIBlocked = blocked
        }
    }
    
    // Get status from centralized cache
    val userStatuses by chatViewModel.userStatuses.collectAsState()
    val (currentIsOnline, currentLastSeen) = userStatuses[user.id] ?: run {
        // Если нет в памяти, пробуем загрузить из кеша
        val cachedLastSeen = cacheManager.getLastSeen(user.id) ?: lastSeen
        Pair(isOnline, cachedLastSeen)
    }
    
    val lastSeenText = remember(currentLastSeen, currentIsOnline) {
        if (currentIsOnline) {
            "в сети"
        } else if (currentLastSeen > 0) {
            val date = java.util.Date(lastSeen)
            val now = java.util.Date()
            val diff = now.time - date.time
            val seconds = diff / 1000
            val minutes = seconds / 60
            val hours = minutes / 60
            val days = hours / 24
            
            when {
                seconds < 30 -> "только что"
                minutes < 1 -> "меньше минуты назад"
                minutes == 1L -> "минуту назад"
                minutes < 5 -> "$minutes минуты назад"
                minutes < 60 -> "$minutes минут назад"
                hours == 1L -> "час назад"
                hours < 5 -> "$hours часа назад"
                hours < 24 -> "$hours часов назад"
                days == 1L -> "вчера"
                days < 7 -> "$days дней назад"
                else -> java.text.SimpleDateFormat("dd.MM.yyyy", java.util.Locale.getDefault()).format(date)
            }
        } else {
            "был(а) давно"
        }
    }
    
    Scaffold(
        modifier = Modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets(0.dp),
        topBar = {
            TopAppBar(
                title = { },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = "Закрыть")
                    }
                },
                actions = {
                    IconButton(onClick = { /* TODO: More options */ }) {
                        Icon(Icons.Filled.MoreVert, contentDescription = "Ещё")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                ),
                windowInsets = WindowInsets(0.dp)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            // Avatar & Info
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                if (amIBlocked) {
                    // Show placeholder avatar if blocked
                    Surface(
                        modifier = Modifier.size(100.dp),
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.surfaceVariant
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Filled.AccountBox,
                                contentDescription = null,
                                modifier = Modifier.size(50.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                            )
                        }
                    }
                } else {
                    AvatarImage(
                        identity = user,
                        cacheManager = cacheManager,
                        size = 100.dp
                    )
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = user.username,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    if (amIBlocked) {
                        // Show "был давно" if blocked
                        Text(
                            text = "был(а) давно",
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    } else {
                        if (currentIsOnline) {
                            Surface(
                                modifier = Modifier.size(8.dp),
                                shape = CircleShape,
                                color = androidx.compose.ui.graphics.Color(0xFF34C759)
                            ) {}
                            Spacer(modifier = Modifier.width(4.dp))
                        }
                        Text(
                            text = lastSeenText,
                            fontSize = 14.sp,
                            color = if (currentIsOnline) androidx.compose.ui.graphics.Color(0xFF34C759) else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = "@${user.username}",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                
                if (user.bio.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = user.bio,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 32.dp)
                    )
                }
            }
            
            // Action Buttons
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                ActionButton(
                    icon = Icons.Filled.Call,
                    label = "Позвонить",
                    color = MaterialTheme.colorScheme.primary,
                    onClick = { /* TODO */ }
                )
                ActionButton(
                    icon = Icons.Filled.PlayArrow,
                    label = "Видео",
                    color = MaterialTheme.colorScheme.tertiary,
                    onClick = { /* TODO */ }
                )
                ActionButton(
                    icon = Icons.Filled.Notifications,
                    label = "Без звука",
                    color = MaterialTheme.colorScheme.secondary,
                    onClick = { /* TODO */ }
                )
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Settings Section
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            ) {
                Column {
                    ContactSettingsItem(
                        icon = Icons.Filled.Notifications,
                        title = "Уведомления",
                        onClick = { /* TODO */ }
                    )
                    
                    Divider(
                        modifier = Modifier.padding(horizontal = 16.dp),
                        thickness = 0.5.dp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)
                    )
                    
                    ContactSettingsItem(
                        icon = if (isBlocked) Icons.Filled.Check else Icons.Filled.Close,
                        title = if (isBlocked) "Разблокировать" else "Заблокировать",
                        onClick = {
                            if (isBlocked) {
                                showUnblockDialog = true
                            } else {
                                showBlockDialog = true
                            }
                        },
                        textColor = if (isBlocked) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.error
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Media Section
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Медиа",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    
                    TextButton(onClick = { /* TODO: Show all */ }) {
                        Text("Все")
                    }
                }
                
                Spacer(modifier = Modifier.height(12.dp))
                
                // Media Tabs
                TabRow(
                    selectedTabIndex = selectedMediaTab,
                    containerColor = MaterialTheme.colorScheme.surface,
                    contentColor = MaterialTheme.colorScheme.primary
                ) {
                    Tab(
                        selected = selectedMediaTab == 0,
                        onClick = { selectedMediaTab = 0 },
                        text = { Text("Фото") }
                    )
                    Tab(
                        selected = selectedMediaTab == 1,
                        onClick = { selectedMediaTab = 1 },
                        text = { Text("Видео") }
                    )
                    Tab(
                        selected = selectedMediaTab == 2,
                        onClick = { selectedMediaTab = 2 },
                        text = { Text("Файлы") }
                    )
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Media Grid (placeholder)
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.height(300.dp),
                    horizontalArrangement = Arrangement.spacedBy(2.dp),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    items(6) {
                        Surface(
                            modifier = Modifier.aspectRatio(1f),
                            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.Filled.AccountBox,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f),
                                    modifier = Modifier.size(32.dp)
                                )
                            }
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
    
    // Block dialog
    if (showBlockDialog) {
        AlertDialog(
            onDismissRequest = { showBlockDialog = false },
            title = { Text("Заблокировать пользователя?") },
            text = { Text("Вы не сможете получать сообщения от @${user.username}") },
            confirmButton = {
                TextButton(
                    onClick = {
                        coroutineScope.launch {
                            repository.blockUser(currentUserId, user.id).onSuccess {
                                isBlocked = true
                                showBlockDialog = false
                            }
                        }
                    }
                ) {
                    Text("Заблокировать", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showBlockDialog = false }) {
                    Text("Отмена")
                }
            }
        )
    }
    
    // Unblock dialog
    if (showUnblockDialog) {
        AlertDialog(
            onDismissRequest = { showUnblockDialog = false },
            title = { Text("Разблокировать пользователя?") },
            text = { Text("Вы сможете снова получать сообщения от @${user.username}") },
            confirmButton = {
                TextButton(
                    onClick = {
                        coroutineScope.launch {
                            repository.unblockUser(currentUserId, user.id).onSuccess {
                                isBlocked = false
                                showUnblockDialog = false
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
fun ActionButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    color: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Surface(
            modifier = Modifier.size(56.dp),
            shape = CircleShape,
            color = color.copy(alpha = 0.2f)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = label,
            fontSize = 12.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
        )
    }
}

@Composable
fun ContactSettingsItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    onClick: () -> Unit,
    textColor: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurface
) {
    Surface(
        onClick = onClick,
        color = androidx.compose.ui.graphics.Color.Transparent
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = if (textColor == MaterialTheme.colorScheme.error) textColor else MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Text(
                text = title,
                fontSize = 16.sp,
                color = textColor,
                modifier = Modifier.weight(1f)
            )
            
            Icon(
                imageVector = Icons.Filled.KeyboardArrowRight,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
            )
        }
    }
}
