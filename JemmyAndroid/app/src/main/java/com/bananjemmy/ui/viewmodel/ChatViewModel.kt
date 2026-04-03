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

class ChatViewModel : ViewModel() {
    private val repository = JemmyRepository()
    private val webSocket = WebSocketManager.getInstance()
    private val TAG = "ChatViewModel"
    
    private val _chatListState = MutableStateFlow<ChatListState>(ChatListState.Loading())
    val chatListState: StateFlow<ChatListState> = _chatListState.asStateFlow()
    
    private val _messagesState = MutableStateFlow<MessagesState>(MessagesState.Loading)
    val messagesState: StateFlow<MessagesState> = _messagesState.asStateFlow()
    
    private val _isSending = MutableStateFlow(false)
    val isSending: StateFlow<Boolean> = _isSending.asStateFlow()
    
    init {
        setupWebSocketListeners()
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
        val currentState = _messagesState.value
        if (currentState is MessagesState.Success) {
            val updatedMessages = currentState.messages + message
            _messagesState.value = MessagesState.Success(updatedMessages)
        }
        
        // Also update the chat list with the new message
        val chatListState = _chatListState.value
        if (chatListState is ChatListState.Success) {
            val updatedChats = chatListState.chats.map { chat ->
                if (chat.id == message.chatId) {
                    chat.copy(
                        lastMessage = message.content,
                        lastMessageTime = message.createdAt
                    )
                } else {
                    chat
                }
            }
            _chatListState.value = ChatListState.Success(updatedChats)
        }
    }
    
    fun loadChats(identityId: String) {
        viewModelScope.launch {
            // Keep existing chats while loading
            val currentChats = (_chatListState.value as? ChatListState.Success)?.chats ?: emptyList()
            _chatListState.value = ChatListState.Loading(currentChats)
            
            Log.d(TAG, "📡 Loading chats for: $identityId")
            
            repository.getChats(identityId).fold(
                onSuccess = { chats ->
                    Log.d(TAG, "✅ Chats loaded: ${chats.size}")
                    _chatListState.value = ChatListState.Success(chats)
                },
                onFailure = { error ->
                    Log.e(TAG, "❌ Failed to load chats", error)
                    _chatListState.value = ChatListState.Error(error.message ?: "Failed to load chats")
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
            _messagesState.value = MessagesState.Loading
            Log.d(TAG, "Loading messages for chat: $chatId")
            
            repository.getMessages(chatId).fold(
                onSuccess = { messages ->
                    Log.d(TAG, "Messages loaded: ${messages.size}")
                    _messagesState.value = MessagesState.Success(messages)
                },
                onFailure = { error ->
                    Log.e(TAG, "Failed to load messages", error)
                    _messagesState.value = MessagesState.Error(error.message ?: "Failed to load messages")
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
