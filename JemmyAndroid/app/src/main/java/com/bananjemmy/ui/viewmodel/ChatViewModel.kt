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
        Log.d(TAG, "📦 CacheManager: ${if (cacheManager != null) "AVAILABLE ✅" else "NULL ❌"}")
        setupWebSocketListeners()
        
        // Setup online status listener
        webSocket.onUserStatus = { identityId, online, lastSeen ->
            Log.d(TAG, "👤 Status update: $identityId, online=$online")
            updateUserStatus(identityId, online, lastSeen)
        }
    }
    
    private fun updateUserStatus(identityId: String, online: Boolean, lastSeen: Long) {
        Log.d(TAG, "🔄 updateUserStatus called:")
        Log.d(TAG, "   Identity: $identityId")
        Log.d(TAG, "   Online: $online")
        Log.d(TAG, "   Last seen: $lastSeen")
        
        val currentState = _chatListState.value
        Log.d(TAG, "   Current state: ${currentState::class.simpleName}")
        
        if (currentState is ChatListState.Success) {
            Log.d(TAG, "   Chats in state: ${currentState.chats.size}")
            
            val updatedChats = currentState.chats.map { chat ->
                if (chat.user.id == identityId) {
                    Log.d(TAG, "   ✅ Found matching chat for user: ${chat.user.username}")
                    Log.d(TAG, "      Old status: online=${chat.isOnline}, lastSeen=${chat.lastSeen}")
                    Log.d(TAG, "      New status: online=$online, lastSeen=$lastSeen")
                    chat.copy(isOnline = online, lastSeen = lastSeen)
                } else {
                    chat
                }
            }
            
            _chatListState.value = ChatListState.Success(updatedChats)
            Log.d(TAG, "   ✅ Chat list state updated")
        } else {
            Log.d(TAG, "   ⚠️ Cannot update - state is not Success")
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
            Log.d(TAG, "🔄 loadChats called for: $identityId")
            _isRefreshing.value = true
            
            // Показываем Loading состояние без кешированных данных
            _chatListState.value = ChatListState.Loading()
            
            Log.d(TAG, "📡 Loading chats from server for: $identityId")
            
            repository.getChats(identityId).fold(
                onSuccess = { chats ->
                    Log.d(TAG, "✅ Chats loaded from server: ${chats.size}")
                    _chatListState.value = ChatListState.Success(chats)
                    _isRefreshing.value = false
                    
                    // Запрашиваем статусы для всех пользователей в чатах
                    chats.forEach { chat ->
                        Log.d(TAG, "🔍 Requesting status for user: ${chat.user.id}")
                        webSocket.requestUserStatus(chat.user.id)
                    }
                    
                    // Сохраняем в кеш или очищаем если пусто
                    cacheManager?.let { cache ->
                        viewModelScope.launch {
                            if (chats.isEmpty()) {
                                Log.d(TAG, "🗑️ Server returned empty list, clearing cache...")
                                cache.clearAllCache()
                                Log.d(TAG, "✅ Cache cleared")
                            } else {
                                Log.d(TAG, "💾 Saving ${chats.size} chats to cache...")
                                cache.cacheChats(chats)
                                Log.d(TAG, "✅ Chats saved to cache successfully")
                            }
                        }
                    } ?: Log.d(TAG, "❌ Cannot save to cache - CacheManager is NULL!")
                },
                onFailure = { error ->
                    Log.e(TAG, "❌ Failed to load chats from server: ${error.message}", error)
                    _isRefreshing.value = false
                    
                    // Только при ошибке загружаем из кеша как fallback
                    cacheManager?.let { cache ->
                        viewModelScope.launch {
                            val cachedChats = cache.getCachedChats()
                            if (cachedChats.isNotEmpty()) {
                                Log.d(TAG, "📦 Using ${cachedChats.size} cached chats as fallback")
                                _chatListState.value = ChatListState.Success(cachedChats)
                            } else {
                                Log.d(TAG, "⚠️ No cached data available, showing error")
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
        // Не запускаем новый запрос если уже идет обновление
        if (_isRefreshing.value) {
            Log.d(TAG, "⏭️ Skipping refresh - already refreshing")
            return
        }
        
        viewModelScope.launch {
            // НЕ показываем индикатор при обычном polling
            // _isRefreshing.value = true
            
            Log.d(TAG, "🔄 Refreshing chats...")
            
            // Тихое обновление без показа Loading
            repository.getChats(identityId).fold(
                onSuccess = { chats ->
                    Log.d(TAG, "✅ Chats refreshed: ${chats.size}")
                    _chatListState.value = ChatListState.Success(chats)
                    
                    // Сохраняем в кеш или очищаем если пусто
                    cacheManager?.let { cache ->
                        viewModelScope.launch {
                            if (chats.isEmpty()) {
                                Log.d(TAG, "🗑️ Server returned empty list, clearing cache...")
                                cache.clearAllCache()
                            } else {
                                cache.cacheChats(chats)
                            }
                        }
                    }
                    
                    // Сбрасываем индикатор если он был (после ошибки)
                    _isRefreshing.value = false
                },
                onFailure = { error ->
                    Log.e(TAG, "❌ Failed to refresh chats: ${error.message}")
                    // Показываем индикатор только при ошибке (нет связи)
                    _isRefreshing.value = true
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
                        // Обновляем только если количество сообщений изменилось
                        if (messages.size > currentState.messages.size) {
                            _messagesState.value = MessagesState.Success(messages)
                        }
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
