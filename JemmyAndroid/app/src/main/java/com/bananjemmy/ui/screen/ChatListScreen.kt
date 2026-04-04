package com.bananjemmy.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.Chat
import com.bananjemmy.ui.viewmodel.ChatListState
import java.text.SimpleDateFormat
import java.util.*
import kotlinx.coroutines.launch
import com.bananjemmy.ui.components.AvatarImage

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatListScreen(
    chatListState: ChatListState,
    currentUserId: String,
    onChatClick: (Chat) -> Unit,
    onRefresh: () -> Unit,
    isRefreshing: Boolean = false,
    onSearchClick: () -> Unit = {},
    cacheManager: com.bananjemmy.data.cache.CacheManager
) {
    val coroutineScope = rememberCoroutineScope()
    val repository = remember { com.bananjemmy.data.repository.JemmyRepository() }
    
    Scaffold(
        modifier = Modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets(0.dp),
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Text(
                            "Чаты",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        if (isRefreshing) {
                            Spacer(modifier = Modifier.width(12.dp))
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                },
                actions = {
                    IconButton(onClick = onSearchClick) {
                        Icon(
                            imageVector = Icons.Filled.Search,
                            contentDescription = "Поиск"
                        )
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                ),
                windowInsets = WindowInsets(0.dp)
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when (chatListState) {
                is ChatListState.Loading -> {
                    if (chatListState.chats.isEmpty()) {
                        CircularProgressIndicator(
                            modifier = Modifier.align(Alignment.Center)
                        )
                    } else {
                        // Show cached chats while loading
                        ChatList(
                            chats = chatListState.chats,
                            currentUserId = currentUserId,
                            onChatClick = onChatClick,
                            onDeleteChat = { chat ->
                                coroutineScope.launch {
                                    repository.deleteChat(chat.id)
                                    cacheManager.clearChatCache(chat.id)
                                    onRefresh()
                                }
                            },
                            onTogglePin = { chat ->
                                coroutineScope.launch {
                                    repository.togglePinChat(chat.id, chat.isPinned)
                                    onRefresh()
                                }
                            },
                            cacheManager = cacheManager
                        )
                    }
                }
                
                is ChatListState.Success -> {
                    if (chatListState.chats.isEmpty()) {
                        EmptyChatList()
                    } else {
                        ChatList(
                            chats = chatListState.chats,
                            currentUserId = currentUserId,
                            onChatClick = onChatClick,
                            onDeleteChat = { chat ->
                                coroutineScope.launch {
                                    repository.deleteChat(chat.id)
                                    cacheManager.clearChatCache(chat.id)
                                    onRefresh()
                                }
                            },
                            onTogglePin = { chat ->
                                coroutineScope.launch {
                                    repository.togglePinChat(chat.id, chat.isPinned)
                                    onRefresh()
                                }
                            },
                            cacheManager = cacheManager
                        )
                    }
                }
                
                is ChatListState.Error -> {
                    Column(
                        modifier = Modifier
                            .align(Alignment.Center)
                            .padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Warning,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Ошибка загрузки",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = chatListState.message,
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = onRefresh) {
                            Text("Повторить")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ChatList(
    chats: List<Chat>,
    currentUserId: String,
    onChatClick: (Chat) -> Unit,
    onDeleteChat: (Chat) -> Unit,
    onTogglePin: (Chat) -> Unit,
    cacheManager: com.bananjemmy.data.cache.CacheManager
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        items(chats, key = { it.id }) { chat ->
            ChatListItem(
                chat = chat,
                currentUserId = currentUserId,
                onClick = { onChatClick(chat) },
                onDelete = { onDeleteChat(chat) },
                onTogglePin = { onTogglePin(chat) },
                modifier = Modifier.animateItem(),
                cacheManager = cacheManager
            )
            Divider(
                modifier = Modifier.padding(start = 88.dp),
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f)
            )
        }
    }
}

@Composable
fun ChatListItem(
    chat: Chat,
    currentUserId: String,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    onTogglePin: () -> Unit,
    modifier: Modifier = Modifier,
    cacheManager: com.bananjemmy.data.cache.CacheManager
) {
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { dismissValue ->
            when (dismissValue) {
                SwipeToDismissBoxValue.EndToStart -> {
                    onDelete()
                    true
                }
                SwipeToDismissBoxValue.StartToEnd -> {
                    onTogglePin()
                    false // Не удаляем элемент, только закрепляем
                }
                else -> false
            }
        }
    )
    
    SwipeToDismissBox(
        state = dismissState,
        backgroundContent = {
            val direction = dismissState.dismissDirection
            when (direction) {
                // Свайп влево - удаление (красный)
                SwipeToDismissBoxValue.EndToStart -> {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(MaterialTheme.colorScheme.error)
                            .padding(horizontal = 20.dp),
                        contentAlignment = Alignment.CenterEnd
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Delete,
                            contentDescription = "Удалить",
                            tint = MaterialTheme.colorScheme.onError,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
                // Свайп вправо - закрепление (синий)
                SwipeToDismissBoxValue.StartToEnd -> {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(MaterialTheme.colorScheme.primary)
                            .padding(horizontal = 20.dp),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        Icon(
                            imageVector = if (chat.isPinned) Icons.Filled.Star else Icons.Outlined.Star,
                            contentDescription = if (chat.isPinned) "Открепить" else "Закрепить",
                            tint = MaterialTheme.colorScheme.onPrimary,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
                else -> {}
            }
        },
        modifier = modifier,
        enableDismissFromStartToEnd = true,
        enableDismissFromEndToStart = true
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .clickable(onClick = onClick),
            color = if (chat.isPinned) MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f) 
                    else MaterialTheme.colorScheme.background
        ) {
        Row(
            modifier = Modifier
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar with unread badge and online indicator
            Box {
                AvatarImage(
                    identity = chat.user,
                    cacheManager = cacheManager,
                    size = 56.dp
                )
                
                // Online indicator
                if (chat.isOnline == true) {
                    Surface(
                        modifier = Modifier
                            .size(14.dp)
                            .align(Alignment.BottomEnd)
                            .offset(x = (-2).dp, y = (-2).dp),
                        shape = CircleShape,
                        color = Color(0xFF34C759), // Green
                        border = androidx.compose.foundation.BorderStroke(2.dp, MaterialTheme.colorScheme.surface)
                    ) {}
                }
                
                // Unread badge
                if (chat.unreadCount > 0 && !chat.isMuted) {
                    Surface(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .offset(x = 4.dp, y = (-4).dp),
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.primary
                    ) {
                        Box(
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = if (chat.unreadCount > 99) "99+" else chat.unreadCount.toString(),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            // Chat info
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    // Username with pin icon
                    Row(
                        modifier = Modifier.weight(1f),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (chat.isPinned) {
                            Icon(
                                imageVector = Icons.Filled.Star,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                        }
                        
                        Text(
                            text = chat.user.username,
                            fontSize = 17.sp,
                            fontWeight = if (chat.unreadCount > 0) FontWeight.Bold else FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onBackground,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                    
                    // Time in top right corner
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (chat.isMuted) {
                            Text(
                                text = "🔕",
                                fontSize = 14.sp,
                                modifier = Modifier.padding(end = 4.dp)
                            )
                        }
                        
                        Text(
                            text = formatTime(chat.lastMessageTime),
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = if (chat.lastMessage.isEmpty()) "Начните переписку" else chat.lastMessage,
                    fontSize = 15.sp,
                    fontWeight = if (chat.unreadCount > 0) FontWeight.Medium else FontWeight.Normal,
                    color = if (chat.unreadCount > 0) 
                            MaterialTheme.colorScheme.onBackground.copy(alpha = 0.9f)
                            else MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
        }
    }
}

@Composable
fun EmptyChatList() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Surface(
            modifier = Modifier.size(80.dp),
            shape = CircleShape,
            color = MaterialTheme.colorScheme.surfaceVariant
        ) {
            Box(contentAlignment = Alignment.Center) {
                Text(
                    text = "💬",
                    fontSize = 40.sp
                )
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "Нет чатов",
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "Создайте invite-ссылку или используйте чужую для начала общения",
            fontSize = 15.sp,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
    }
}

private fun formatTime(timestamp: String): String {
    if (timestamp.isEmpty()) return ""
    
    return try {
        val formatter = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault())
        formatter.timeZone = java.util.TimeZone.getTimeZone("UTC")
        val date = formatter.parse(timestamp) ?: return ""
        
        val now = Date()
        val diff = now.time - date.time
        
        val calendar = Calendar.getInstance()
        calendar.time = date
        val today = Calendar.getInstance()
        
        when {
            diff < 60000 -> "сейчас"
            diff < 3600000 -> "${diff / 60000}м"
            calendar.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR) -> {
                val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
                timeFormat.format(date)
            }
            diff < 86400000 -> "вчера"
            else -> {
                val dateFormat = SimpleDateFormat("dd.MM.yy", Locale.getDefault())
                dateFormat.format(date)
            }
        }
    } catch (e: Exception) {
        ""
    }
}
