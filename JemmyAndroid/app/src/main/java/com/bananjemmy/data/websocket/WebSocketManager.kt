package com.bananjemmy.data.websocket

import android.util.Log
import com.bananjemmy.data.model.Message
import com.google.gson.Gson
import io.socket.client.IO
import io.socket.client.Socket
import org.json.JSONObject

class WebSocketManager private constructor() {
    private var socket: Socket? = null
    private val gson = Gson()
    private val TAG = "WebSocketManager"
    
    var isConnected = false
        private set
    
    var onMessageReceived: ((Message) -> Unit)? = null
    var onUnreadUpdate: ((String, Int) -> Unit)? = null
    var onPinUpdate: ((String, Boolean) -> Unit)? = null
    var onMuteUpdate: ((String, Boolean) -> Unit)? = null
    var onUserStatus: ((String, Boolean, Long) -> Unit)? = null // identity_id, online, last_seen
    var onMessageStatusUpdate: ((String, Boolean, Boolean) -> Unit)? = null // message_id, delivered, read
    
    companion object {
        @Volatile
        private var instance: WebSocketManager? = null
        
        fun getInstance(): WebSocketManager {
            return instance ?: synchronized(this) {
                instance ?: WebSocketManager().also { instance = it }
            }
        }
    }
    
    fun connect(userId: String, identityId: String) {
        try {
            val opts = IO.Options().apply {
                reconnection = true
                reconnectionDelay = 1000
                reconnectionDelayMax = 5000
                forceNew = false
                multiplex = true
            }
            
            // Подключаемся к реальному серверу с WebSocket
            socket = IO.socket("http://178.104.40.37:25593", opts)
            
            socket?.on(Socket.EVENT_CONNECT) {
                Log.d(TAG, "✅ WebSocket connected")
                isConnected = true
                register(userId, identityId)
            }
            
            socket?.on(Socket.EVENT_DISCONNECT) {
                Log.d(TAG, "❌ WebSocket disconnected")
                isConnected = false
            }
            
            socket?.on(Socket.EVENT_CONNECT_ERROR) { args ->
                val error = args.firstOrNull()
                Log.e(TAG, "❌ WebSocket connection error")
                Log.e(TAG, "   Error: $error")
                
                // Vercel не поддерживает WebSocket
                if (error.toString().contains("server error")) {
                    Log.w(TAG, "⚠️ Vercel не поддерживает WebSocket")
                }
            }
            
            socket?.on("receive_message") { args ->
                handleMessageReceived(args)
            }
            
            socket?.on("unread_update") { args ->
                handleUnreadUpdate(args)
            }
            
            socket?.on("pin_update") { args ->
                handlePinUpdate(args)
            }
            
            socket?.on("mute_update") { args ->
                handleMuteUpdate(args)
            }
            
            socket?.on("user_status") { args ->
                handleUserStatus(args)
            }
            
            socket?.on("message_status_update") { args ->
                handleMessageStatusUpdate(args)
            }
            
            socket?.connect()
            Log.d(TAG, "📡 Connecting to WebSocket at https://weeky-six.vercel.app/api/")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error connecting to WebSocket", e)
        }
    }
    
    fun disconnect() {
        socket?.disconnect()
        socket?.off()
        socket = null
        isConnected = false
        Log.d(TAG, "🔌 WebSocket disconnected")
    }
    
    private fun register(userId: String, identityId: String) {
        try {
            val data = JSONObject().apply {
                put("identity_id", identityId)
            }
            socket?.emit("register", data)
            Log.d(TAG, "📝 Registered with identity_id: $identityId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error registering", e)
        }
    }
    
    fun requestUserStatus(identityId: String) {
        try {
            val data = JSONObject().apply {
                put("identity_id", identityId)
            }
            socket?.emit("request_status", data)
            Log.d(TAG, "🔍 Requested status for: $identityId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error requesting status", e)
        }
    }
    
    fun joinChat(chatId: String) {
        try {
            val data = JSONObject().apply {
                put("chat_id", chatId)
            }
            socket?.emit("join_chat", data)
            Log.d(TAG, "🚪 Joined chat: $chatId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error joining chat", e)
        }
    }
    
    fun sendMessage(chatId: String, senderIdentityId: String, content: String) {
        try {
            val data = JSONObject().apply {
                put("chat_id", chatId)
                put("sender_identity_id", senderIdentityId)
                put("encrypted_content", content)
                put("type", "text")
            }
            socket?.emit("send_message", data)
            Log.d(TAG, "📤 Sent message to chat: $chatId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error sending message", e)
        }
    }
    
    fun markAsRead(chatId: String, identityId: String) {
        try {
            val data = JSONObject().apply {
                put("chat_id", chatId)
                put("identity_id", identityId)
            }
            socket?.emit("mark_read", data)
            Log.d(TAG, "✅ Marked chat as read: $chatId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error marking as read", e)
        }
    }
    
    fun togglePin(chatId: String, identityId: String) {
        try {
            val data = JSONObject().apply {
                put("chat_id", chatId)
                put("identity_id", identityId)
            }
            socket?.emit("toggle_pin", data)
            Log.d(TAG, "📌 Toggled pin for chat: $chatId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error toggling pin", e)
        }
    }
    
    fun toggleMute(chatId: String, identityId: String) {
        try {
            val data = JSONObject().apply {
                put("chat_id", chatId)
                put("identity_id", identityId)
            }
            socket?.emit("toggle_mute", data)
            Log.d(TAG, "🔕 Toggled mute for chat: $chatId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error toggling mute", e)
        }
    }
    
    fun markMessageDelivered(messageId: String, chatId: String) {
        try {
            val data = JSONObject().apply {
                put("message_id", messageId)
                put("chat_id", chatId)
            }
            socket?.emit("message_delivered", data)
            Log.d(TAG, "✅ Marked message as delivered: $messageId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error marking message as delivered", e)
        }
    }
    
    fun markMessageRead(messageId: String, chatId: String) {
        try {
            val data = JSONObject().apply {
                put("message_id", messageId)
                put("chat_id", chatId)
            }
            socket?.emit("message_read", data)
            Log.d(TAG, "✅ Marked message as read: $messageId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error marking message as read", e)
        }
    }
    
    private fun handleMessageReceived(args: Array<Any>) {
        try {
            val data = args.firstOrNull() as? JSONObject ?: return
            val message = gson.fromJson(data.toString(), Message::class.java)
            onMessageReceived?.invoke(message)
            Log.d(TAG, "📨 Message received: ${message.id}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling message", e)
        }
    }
    
    private fun handleUnreadUpdate(args: Array<Any>) {
        try {
            val data = args.firstOrNull() as? JSONObject ?: return
            val chatId = data.getString("chat_id")
            val unreadCount = data.getInt("unread_count")
            onUnreadUpdate?.invoke(chatId, unreadCount)
            Log.d(TAG, "📬 Unread update: chat=$chatId, count=$unreadCount")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling unread update", e)
        }
    }
    
    private fun handlePinUpdate(args: Array<Any>) {
        try {
            val data = args.firstOrNull() as? JSONObject ?: return
            val chatId = data.getString("chat_id")
            val isPinned = data.getBoolean("is_pinned")
            onPinUpdate?.invoke(chatId, isPinned)
            Log.d(TAG, "📌 Pin update: chat=$chatId, pinned=$isPinned")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling pin update", e)
        }
    }
    
    private fun handleMuteUpdate(args: Array<Any>) {
        try {
            val data = args.firstOrNull() as? JSONObject ?: return
            val chatId = data.getString("chat_id")
            val isMuted = data.getBoolean("is_muted")
            onMuteUpdate?.invoke(chatId, isMuted)
            Log.d(TAG, "🔕 Mute update: chat=$chatId, muted=$isMuted")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling mute update", e)
        }
    }
    
    private fun handleUserStatus(args: Array<Any>) {
        try {
            val data = args.firstOrNull() as? JSONObject ?: return
            Log.d(TAG, "📊 Raw user_status data: $data")
            
            val identityId = data.getString("identity_id")
            val online = data.getBoolean("online")
            val lastSeen = data.getLong("last_seen")
            
            Log.d(TAG, "👤 User status update:")
            Log.d(TAG, "   Identity: $identityId")
            Log.d(TAG, "   Online: $online")
            Log.d(TAG, "   Last seen: $lastSeen")
            
            onUserStatus?.invoke(identityId, online, lastSeen)
            Log.d(TAG, "   ✅ Callback invoked")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling user status", e)
            Log.e(TAG, "   Raw args: ${args.contentToString()}")
        }
    }
    
    private fun handleMessageStatusUpdate(args: Array<Any>) {
        try {
            val data = args.firstOrNull() as? JSONObject ?: return
            val messageId = data.getString("message_id")
            val delivered = data.getBoolean("delivered")
            val read = data.getBoolean("read")
            
            onMessageStatusUpdate?.invoke(messageId, delivered, read)
            Log.d(TAG, "📬 Message status update: id=$messageId, delivered=$delivered, read=$read")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling message status update", e)
        }
    }
}
