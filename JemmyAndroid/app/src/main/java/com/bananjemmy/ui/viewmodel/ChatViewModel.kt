package com.bananjemmy.ui.viewmodel

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bananjemmy.data.model.Chat
import com.bananjemmy.data.model.Message
import com.bananjemmy.data.repository.JemmyRepository
import com.bananjemmy.data.websocket.WebSocketManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed class ChatListState {
    data class Loading(val chats: List<Chat> = emptyList()) : ChatListState()
    data class Success(val chats: List<Chat>) : ChatListState()
    data class Error(val message: String) : ChatListState()
}

sealed class MessagesState {
    object Loading : MessagesState()
    data class Success(val messages: List<Message>) : MessagesState()
    data class Error(val message: String) : MessagesState()
}

class ChatViewModel(private val cacheManager: com.bananjemmy.data.cache.CacheManager? = null) : ViewModel() {
    private val repository = JemmyRepository()
    private val webSocket = WebSocketManager.getInstance()
    private val TAG = "ChatViewModel"
    
    init {
        Log.d(TAG, "🚀 ChatViewModel initialized")
        setupWebSocketListeners()
        
        // Setup online status listener
        webSocket.onUserStatus = { identityId, online, lastSeen ->
            Log.d(TAG, "📲 Received status in ViewModel: $identityId, online=$online")
            updateUserStatus(identityId, online, lastSeen)
        }
        
        // Setup message status listener
        webSocket.onMessageStatusUpdate = { messageId, delivered, read ->
            Log.d(TAG, "📬 Message status update: $messageId, delivered=$delivered, read=$read")
            updateMessageStatus(messageId, delivered, read)
        }
    }
    
    private fun updateUserStatus(identityId: String, online: Boolean, lastSeen: Long) {
        Log.d(TAG, "🔄 updateUserStatus called")
        Log.d(TAG, "   Identity: $identityId")
        Log.d(TAG, "   Online: $online")
        Log.d(TAG, "   Last seen: $lastSeen")
        
        val currentState = _chatListState.value
        Log.d(TAG, "   Current state: ${currentState::class.simpleName}")
        
        if (currentState is ChatListState.Success) {
            Log.d(TAG, "   Chats count: ${currentState.chats.size}")
            
            // Создаем НОВЫЙ список чтобы StateFlow обновился
            val updatedChats = currentState.chats.map { chat ->
                if (chat.user.id == identityId) {
                    Log.d(TAG, "   ✅ Updating chat: ${chat.user.username}")
                    Log.d(TAG, "      Old: online=${chat.isOnline}, lastSeen=${chat.lastSeen}")
                    Log.d(TAG, "      New: online=$online, lastSeen=$lastSeen")
                    chat.copy(isOnline = online, lastSeen = lastSeen)
                } else {
                    chat
                }
            }
            
            // Обновляем StateFlow новым списком
            _chatListState.value = ChatListState.Success(updatedChats)
            Log.d(TAG, "   ✅ StateFlow updated with new list")
        } else {
            Log.d(TAG, "   ⚠️ State is not Success, cannot update")
        }
    }
    
    private fun updateMessageStatus(messageId: String, delivered: Boolean, read: Boolean) {
        val currentState = _messagesState.value
        if (currentState is MessagesState.Success) {
            val updatedMessages = currentState.messages.map { message ->
                if (message.id == messageId) {
                    message.copy(delivered = delivered, read = read)
                } else {
                    message
                }
            }
            _messagesState.value = MessagesState.Success(updatedMessages)
            Log.d(TAG, "✅ Updated message status: $messageId")
            
            // Сохраняем обновленные сообщения в кеш
            val chatId = updatedMessages.firstOrNull()?.chatId
            if (chatId != null) {
                cacheManager?.let { cache ->
                    viewModelScope.launch {
                        cache.cacheMessages(chatId, updatedMessages)
                        Log.d(TAG, "💾 Saved updated messages to cache")
                    }
                }
            }
        }
    }
    
    fun markChatMessagesAsRead(chatId: String, currentUserId: String) {
        viewModelScope.launch {
            val currentState = _messagesState.value
            if (currentState is MessagesState.Success) {
                currentState.messages
                    .filter { it.senderId != currentUserId && !it.read }
                    .forEach { message ->
                        webSocket.markMessageRead(message.id, chatId)
                    }
            }
        }
    }
    
    private val _chatListState = MutableStateFlow<ChatListState>(ChatListState.Loading())
    val chatListState: StateFlow<ChatListState> = _chatListState.asStateFlow()
    
    private val _messagesState = MutableStateFlow<MessagesState>(MessagesState.Loading)
    val messagesState: StateFlow<MessagesState> = _messagesState.asStateFlow()
    
    private val _isSending = MutableStateFlow(false)
    val isSending: StateFlow<Boolean> = _isSending.asStateFlow()
    
    private val _isRefreshing = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()
    
    private val _pendingInvite = MutableStateFlow<Pair<com.bananjemmy.data.model.Identity, String>?>(null)
    val pendingInvite: StateFlow<Pair<com.bananjemmy.data.model.Identity, String>?> = _pendingInvite.asStateFlow()
    
    fun setPendingInvite(identity: com.bananjemmy.data.model.Identity?, token: String?) {
        _pendingInvite.value = if (identity != null && token != null) Pair(identity, token) else null
    }
    
    private fun setupWebSocketListeners() {
        webSocket.onUnreadUpdate = { chatId, unreadCount ->
            updateChatUnreadCount(chatId, unreadCount)
        }
        
        webSocket.onPinUpdate = { chatId, isPinned ->
            updateChatPinStatus(chatId, isPinned)
        }
        
        webSocket.onMuteUpdate = { chatId, isMuted ->
            updateChatMuteStatus(chatId, isMuted)
        }
        
        webSocket.onMessageReceived = { message ->
            addMessageToChat(message)
            
            // Mark as delivered when received
            webSocket.markMessageDelivered(message.id, message.chatId)
        }
    }
    
    fun connectWebSocket(userId: String, identityId: String) {
        webSocket.connect(userId, identityId)
        Log.d(TAG, "🔌 Connecting WebSocket for user: $userId, identity: $identityId")
    }
    
    fun joinChat(chatId: String) {
        webSocket.joinChat(chatId)
        Log.d(TAG, "🚪 Joined chat: $chatId")
    }
    
    fun requestUserStatus(identityId: String) {
        webSocket.requestUserStatus(identityId)
        Log.d(TAG, "🔍 Requested status for: $identityId")
    }
    
    fun disconnectWebSocket() {
        webSocket.disconnect()
    }
    
    private fun updateChatUnreadCount(chatId: String, unreadCount: Int) {
        val currentState = _chatListState.value
        if (currentState is ChatListState.Success) {
            val updatedChats = currentState.chats.map { chat ->
                if (chat.id == chatId) {
                    chat.copy(unreadCount = unreadCount)
                } else {
                    chat
                }
            }
            _chatListState.value = ChatListState.Success(updatedChats)
            Log.d(TAG, "📬 Updated unread count for chat $chatId: $unreadCount")
        }
    }
    
    private fun updateChatPinStatus(chatId: String, isPinned: Boolean) {
        val currentState = _chatListState.value
        if (currentState is ChatListState.Success) {
            val updatedChats = currentState.chats.map { chat ->
                if (chat.id == chatId) {
                    chat.copy(isPinned = isPinned)
                } else {
                    chat
                }
            }
            _chatListState.value = ChatListState.Success(updatedChats)
            Log.d(TAG, "📌 Updated pin status for chat $chatId: $isPinned")
        }
    }
    
    private fun updateChatMuteStatus(chatId: String, isMuted: Boolean) {
        val currentState = _chatListState.value
        if (currentState is ChatListState.Success) {
            val updatedChats = currentState.chats.map { chat ->
                if (chat.id == chatId) {
                    chat.copy(isMuted = isMuted)
                } else {
                    chat
                }
            }
            _chatListState.value = ChatListState.Success(updatedChats)
            Log.d(TAG, "🔕 Updated mute status for chat $chatId: $isMuted")
        }
    }
    
    private fun addMessageToChat(message: Message) {
        Log.d(TAG, "💬 New message received: ${message.id} for chat ${message.chatId}")
        
        // Update messages ONLY if we're viewing this chat
        val currentState = _messagesState.value
        if (currentState is MessagesState.Success) {
            val updatedMessages = currentState.messages.toMutableList()
            updatedMessages.add(message)
            _messagesState.value = MessagesState.Success(updatedMessages)
            Log.d(TAG, "✅ Added message to chat view, total: ${updatedMessages.size}")
        }
        
        // Для списка чатов - просто перезагружаем чаты
        // (как в iOS - там тоже нет обновления lastMessage через WebSocket)
        Log.d(TAG, "📝 Message received, chat list will update on next refresh")
    }
    
    fun loadChats(identityId: String) {
        viewModelScope.launch {
            _isRefreshing.value = true
            _chatListState.value = ChatListState.Loading()
            
            repository.getChats(identityId).fold(
                onSuccess = { chats ->
                    _chatListState.value = ChatListState.Success(chats)
                    _isRefreshing.value = false
                    
                    // Сохраняем в кеш
                    cacheManager?.let { cache ->
                        viewModelScope.launch {
                            if (chats.isEmpty()) {
                                cache.clearAllCache()
                            } else {
                                cache.cacheChats(chats)
                            }
                        }
                    }
                    
                    // Запрашиваем статусы через WebSocket
                    Log.d(TAG, "🔍 Requesting status for ${chats.size} users via WebSocket")
                    chats.forEach { chat ->
                        webSocket.requestUserStatus(chat.user.id)
                    }
                },
                onFailure = { error ->
                    _isRefreshing.value = false
                    
                    // Fallback to cache
                    cacheManager?.let { cache ->
                        viewModelScope.launch {
                            val cachedChats = cache.getCachedChats()
                            if (cachedChats.isNotEmpty()) {
                                _chatListState.value = ChatListState.Success(cachedChats)
                            } else {
                                _chatListState.value = ChatListState.Error(error.message ?: "Failed to load chats")
                            }
                        }
                    } ?: run {
                        _chatListState.value = ChatListState.Error(error.message ?: "Failed to load chats")
                    }
                }
            )
        }
    }
    
    fun refreshChats(identityId: String) {
        if (_isRefreshing.value) return
        
        viewModelScope.launch {
            repository.getChats(identityId).fold(
                onSuccess = { chats ->
                    val currentState = _chatListState.value
                    
                    // Сохраняем текущие статусы
                    val currentStatuses = if (currentState is ChatListState.Success) {
                        currentState.chats.associate { it.user.id to Pair(it.isOnline, it.lastSeen) }
                    } else {
                        emptyMap()
                    }
                    
                    // Восстанавливаем статусы в новых чатах
                    val chatsWithStatus = chats.map { chat ->
                        val (isOnline, lastSeen) = currentStatuses[chat.user.id] ?: Pair(false, 0L)
                        chat.copy(isOnline = isOnline, lastSeen = lastSeen)
                    }
                    
                    _chatListState.value = ChatListState.Success(chatsWithStatus)
                    _isRefreshing.value = false
                    
                    // Сохраняем в кеш
                    cacheManager?.let { cache ->
                        viewModelScope.launch {
                            if (chats.isEmpty()) {
                                cache.clearAllCache()
                            } else {
                                cache.cacheChats(chatsWithStatus)
                            }
                        }
                    }
                    
                    // Запрашиваем свежие статусы только через WebSocket (не HTTP чтобы не перегружать)
                    chats.forEach { chat ->
                        webSocket.requestUserStatus(chat.user.id)
                    }
                },
                onFailure = { error ->
                    _isRefreshing.value = false
                }
            )
        }
    }
    
    fun startChatByToken(token: String, onSuccess: (Chat) -> Unit) {
        viewModelScope.launch {
            Log.d(TAG, "Starting chat by token: $token")
            
            repository.startChatByToken(token).fold(
                onSuccess = { chat ->
                    Log.d(TAG, "Chat started: ${chat.id}")
                    onSuccess(chat)
                },
                onFailure = { error ->
                    Log.e(TAG, "Failed to start chat by token", error)
                }
            )
        }
    }
    
    fun loadMessages(chatId: String) {
        viewModelScope.launch {
            Log.d(TAG, "🔄 loadMessages called for chat: $chatId")
            
            // Сначала загружаем из кеша
            cacheManager?.let { cache ->
                Log.d(TAG, "📦 CacheManager is available, loading messages from cache...")
                val cachedMessages = cache.getCachedMessages(chatId)
                if (cachedMessages.isNotEmpty()) {
                    Log.d(TAG, "✅ Loaded ${cachedMessages.size} messages from cache")
                    _messagesState.value = MessagesState.Success(cachedMessages)
                } else {
                    Log.d(TAG, "⚠️ No cached messages for this chat")
                }
            } ?: Log.d(TAG, "❌ CacheManager is NULL!")
            
            Log.d(TAG, "📡 Loading messages from server for chat: $chatId")
            
            repository.getMessages(chatId).fold(
                onSuccess = { messages ->
                    Log.d(TAG, "✅ Messages loaded from server: ${messages.size}")
                    _messagesState.value = MessagesState.Success(messages)
                    
                    // Сохраняем в кеш
                    cacheManager?.let { cache ->
                        viewModelScope.launch {
                            Log.d(TAG, "💾 Saving ${messages.size} messages to cache...")
                            cache.cacheMessages(chatId, messages)
                            Log.d(TAG, "✅ Messages saved to cache successfully")
                        }
                    } ?: Log.d(TAG, "❌ Cannot save to cache - CacheManager is NULL!")
                },
                onFailure = { error ->
                    Log.e(TAG, "❌ Failed to load messages from server: ${error.message}", error)
                    // Если есть кешированные данные, оставляем их
                    val currentState = _messagesState.value
                    if (currentState !is MessagesState.Success || currentState.messages.isEmpty()) {
                        Log.d(TAG, "⚠️ No cached messages available, showing error")
                        _messagesState.value = MessagesState.Error(error.message ?: "Failed to load messages")
                    } else {
                        Log.d(TAG, "📦 Using cached messages due to server error")
                    }
                }
            )
        }
    }
    
    fun refreshMessages(chatId: String) {
        viewModelScope.launch {
            // Тихое обновление без показа Loading
            repository.getMessages(chatId).fold(
                onSuccess = { messages ->
                    val currentState = _messagesState.value
                    if (currentState is MessagesState.Success) {
                        // Всегда обновляем, чтобы получить актуальные статусы
                        _messagesState.value = MessagesState.Success(messages)
                    }
                },
                onFailure = { 
                    // Игнорируем ошибки при polling
                }
            )
        }
    }
    
    fun sendMessage(chatId: String, senderIdentityId: String, content: String) {
        viewModelScope.launch {
            _isSending.value = true
            Log.d(TAG, "Sending message to chat: $chatId")
            
            repository.sendMessage(chatId, senderIdentityId, content).fold(
                onSuccess = { message ->
                    Log.d(TAG, "Message sent: ${message.id}")
                    // Reload messages to include the new one
                    loadMessages(chatId)
                    _isSending.value = false
                },
                onFailure = { error ->
                    Log.e(TAG, "Failed to send message", error)
                    _isSending.value = false
                }
            )
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        disconnectWebSocket()
    }
}
