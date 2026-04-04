package com.bananjemmy.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.Identity
import com.bananjemmy.data.model.Message
import com.bananjemmy.ui.viewmodel.ChatViewModel
import com.bananjemmy.ui.viewmodel.MessagesState
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    chatId: String,
    otherUser: Identity,
    currentUserId: String,
    chatViewModel: ChatViewModel,
    onBack: () -> Unit,
    isOnline: Boolean = false,
    lastSeen: Long = 0
) {
    val messagesState by chatViewModel.messagesState.collectAsState()
    val isSending by chatViewModel.isSending.collectAsState()
    val chatListState by chatViewModel.chatListState.collectAsState()
    
    // Get real-time status from chat list state
    val currentChat = remember(chatListState) {
        if (chatListState is com.bananjemmy.ui.viewmodel.ChatListState.Success) {
            (chatListState as com.bananjemmy.ui.viewmodel.ChatListState.Success).chats
                .find { it.user.id == otherUser.id }
        } else null
    }
    
    val currentIsOnline = currentChat?.isOnline ?: isOnline
    val currentLastSeen = currentChat?.lastSeen ?: lastSeen
    
    var messageText by remember { mutableStateOf("") }
    val listState = rememberLazyListState()
    val coroutineScope = rememberCoroutineScope()
    var showContactProfile by remember { mutableStateOf(false) }
    var showSearch by remember { mutableStateOf(false) }
    
    // Format last seen time
    val lastSeenText = remember(currentLastSeen, currentIsOnline) {
        when {
            currentIsOnline == true -> "в сети"
            currentLastSeen != null && currentLastSeen > 0 -> {
                val date = Date(currentLastSeen)
                val now = Date()
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
                    else -> SimpleDateFormat("dd.MM.yyyy", Locale.getDefault()).format(date)
                }
            }
            else -> "" // Не показываем статус пока не загрузился
        }
    }
    
    LaunchedEffect(chatId) {
        chatViewModel.loadMessages(chatId)
        chatViewModel.joinChat(chatId)
        chatViewModel.requestUserStatus(otherUser.id)
        
        // Mark all messages as read when opening chat
        chatViewModel.markChatMessagesAsRead(chatId, currentUserId)
    }
    
    // Polling для обновления статуса каждые 2 секунды
    LaunchedEffect(otherUser.id) {
        while (true) {
            kotlinx.coroutines.delay(2000)
            chatViewModel.requestUserStatus(otherUser.id)
        }
    }
    
    // Polling для обновления сообщений каждые 0.5 секунды
    LaunchedEffect(chatId) {
        while (true) {
            kotlinx.coroutines.delay(500)
            chatViewModel.refreshMessages(chatId)
        }
    }
    
    // Auto-scroll to bottom when new messages arrive
    LaunchedEffect(messagesState) {
        if (messagesState is MessagesState.Success) {
            val messages = (messagesState as MessagesState.Success).messages
            if (messages.isNotEmpty()) {
                coroutineScope.launch {
                    listState.scrollToItem(0) // Скролл к первому элементу (т.к. reverseLayout)
                }
            }
        }
    }
    
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Scaffold(
            modifier = Modifier
                .fillMaxSize()
                .imePadding(),
            topBar = {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .statusBarsPadding()
                ) {
                TopAppBar(
                    title = {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .clickable { showContactProfile = true }
                                .padding(vertical = 4.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = otherUser.username,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.Center
                                ) {
                                    if (currentIsOnline) {
                                        Surface(
                                            modifier = Modifier.size(8.dp),
                                            shape = CircleShape,
                                            color = Color(0xFF34C759)
                                        ) {}
                                        Spacer(modifier = Modifier.width(4.dp))
                                    }
                                    Text(
                                        text = lastSeenText,
                                        fontSize = 12.sp,
                                        color = if (currentIsOnline) Color(0xFF34C759) else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                    )
                                }
                            }
                        }
                    },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.Filled.ArrowBack, contentDescription = "Назад")
                        }
                    },
                    actions = {
                        IconButton(onClick = { showContactProfile = true }) {
                            Surface(
                                modifier = Modifier.size(36.dp),
                                shape = CircleShape,
                                color = MaterialTheme.colorScheme.primaryContainer
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Text(
                                        text = otherUser.username.take(2).uppercase(),
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                }
                            }
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                    )
                )
                Divider(
                    modifier = Modifier.fillMaxWidth(),
                    thickness = 0.5.dp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)
                )
            }
        }
    ) { paddingValues ->
        // Messages
        Column(
            modifier = Modifier
                .fillMaxSize()
        ) {
            // Список сообщений
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(top = paddingValues.calculateTopPadding())
            ) {
            when (val state = messagesState) {
                    is MessagesState.Loading -> {
                        CircularProgressIndicator(
                            modifier = Modifier.align(Alignment.Center)
                        )
                    }
                    is MessagesState.Success -> {
                        if (state.messages.isEmpty()) {
                            Text(
                                text = "Нет сообщений",
                                modifier = Modifier.align(Alignment.Center),
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                            )
                        } else {
                            LazyColumn(
                                state = listState,
                                modifier = Modifier.fillMaxSize(),
                                contentPadding = PaddingValues(
                                    start = 16.dp,
                                    end = 16.dp,
                                    top = 16.dp,
                                    bottom = 8.dp
                                ),
                                verticalArrangement = Arrangement.spacedBy(8.dp),
                                reverseLayout = true
                            ) {
                                val reversedMessages = state.messages.reversed()
                                items(reversedMessages.size, key = { reversedMessages[it].id }) { index ->
                                    val message = reversedMessages[index]
                                    val isFromMe = message.senderId == currentUserId
                                    
                                    // Проверяем, последнее ли это сообщение в блоке от меня
                                    val isLastInBlock = if (isFromMe) {
                                        index == 0 || reversedMessages[index - 1].senderId != currentUserId
                                    } else {
                                        false
                                    }
                                    
                                    MessageBubble(
                                        message = message,
                                        isFromMe = isFromMe,
                                        showStatus = isLastInBlock,
                                        modifier = Modifier.animateItem()
                                    )
                                }
                            }
                        }
                    }
                    is MessagesState.Error -> {
                        Column(
                            modifier = Modifier.align(Alignment.Center),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = "Ошибка загрузки сообщений",
                                color = MaterialTheme.colorScheme.error
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Button(onClick = { chatViewModel.loadMessages(chatId) }) {
                                Text("Повторить")
                            }
                        }
                    }
                }
            }
            
            // Поле ввода сообщения (без imePadding)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
            ) {
                Divider(
                    modifier = Modifier.fillMaxWidth(),
                    thickness = 0.5.dp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)
                )
                
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.surface
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.Bottom
                    ) {
                        OutlinedTextField(
                            value = messageText,
                            onValueChange = { messageText = it },
                            modifier = Modifier.weight(1f),
                            placeholder = { Text("Сообщение") },
                            shape = RoundedCornerShape(24.dp),
                            maxLines = 4
                        )
                        
                        Spacer(modifier = Modifier.width(8.dp))
                        
                        IconButton(
                            onClick = {
                                if (messageText.isNotBlank()) {
                                    chatViewModel.sendMessage(chatId, currentUserId, messageText.trim())
                                    messageText = ""
                                }
                            },
                            enabled = messageText.isNotBlank() && !isSending,
                            modifier = Modifier.size(48.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Send,
                                contentDescription = "Отправить",
                                tint = if (messageText.isNotBlank()) 
                                    MaterialTheme.colorScheme.primary 
                                else 
                                    MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                            )
                        }
                    }
                }
            }
        }
    }
    }
    
    // Contact Profile Dialog
    if (showContactProfile) {
        androidx.compose.ui.window.Dialog(
            onDismissRequest = { showContactProfile = false },
            properties = androidx.compose.ui.window.DialogProperties(
                usePlatformDefaultWidth = false
            )
        ) {
            ContactProfileScreen(
                user = otherUser,
                onDismiss = { showContactProfile = false },
                isOnline = isOnline,
                lastSeen = lastSeen
            )
        }
    }
}

@Composable
fun MessageBubble(
    message: Message,
    isFromMe: Boolean,
    showStatus: Boolean = true,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = if (isFromMe) Arrangement.End else Arrangement.Start
    ) {
        Column(
            modifier = Modifier.widthIn(max = 280.dp),
            horizontalAlignment = if (isFromMe) Alignment.End else Alignment.Start
        ) {
            Box {
                // Текст сообщения с отступом справа для времени
                Text(
                    text = message.content + "        ",
                    fontSize = 14.sp,
                    color = Color.White,
                    modifier = Modifier
                        .background(
                            color = if (isFromMe) {
                                Color(0xFF4CAF50).copy(alpha = 0.8f)
                            } else {
                                Color.White.copy(alpha = 0.1f)
                            },
                            shape = RoundedCornerShape(16.dp)
                        )
                        .padding(horizontal = 12.dp, vertical = 8.dp)
                )
                
                // Время справа внизу
                Text(
                    text = formatTime(message.getDisplayTime()),
                    fontSize = 11.sp,
                    color = Color.White.copy(alpha = 0.5f),
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(end = 8.dp, bottom = 4.dp)
                )
            }
            
            // Статус доставки/прочтения (только для последнего сообщения в блоке)
            if (isFromMe && showStatus) {
                Text(
                    text = when {
                        message.read -> "прочитано"
                        message.delivered -> "доставлено"
                        else -> "отправлено"
                    },
                    fontSize = 10.sp,
                    color = Color.White.copy(alpha = 0.4f),
                    modifier = Modifier.padding(top = 2.dp, end = 4.dp)
                )
            }
        }
    }
}

private fun formatTime(timestamp: String): String {
    return try {
        val inputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault())
        inputFormat.timeZone = TimeZone.getTimeZone("UTC")
        val date = inputFormat.parse(timestamp)
        
        val outputFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        date?.let { outputFormat.format(it) } ?: timestamp
    } catch (e: Exception) {
        timestamp
    }
}

private fun formatTime(timestamp: Long): String {
    return try {
        val date = Date(timestamp)
        val outputFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        outputFormat.format(date)
    } catch (e: Exception) {
        ""
    }
}
