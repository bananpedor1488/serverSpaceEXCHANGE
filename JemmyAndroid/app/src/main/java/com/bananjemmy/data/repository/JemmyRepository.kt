package com.bananjemmy.data.repository

import android.util.Log
import com.bananjemmy.data.api.PinChatRequest
import com.bananjemmy.data.api.RetrofitClient
import com.bananjemmy.data.model.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class JemmyRepository {
    private val api = RetrofitClient.apiService
    private val TAG = "JemmyRepository"
    
    // Identity operations
    suspend fun checkDevice(deviceId: String): Result<DeviceCheckResponse> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "📡 Request: GET /api/auth/check-device/$deviceId")
                
                val response = api.checkDevice(deviceId)
                
                if (response.isSuccessful && response.body() != null) {
                    val result = response.body()!!
                    Log.d(TAG, "✅ Device check: exists=${result.exists}")
                    Result.success(result)
                } else {
                    Log.e(TAG, "❌ Device check failed: ${response.code()}")
                    Result.failure(Exception("Failed to check device"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Device check error", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun createIdentity(deviceId: String, ephemeral: Boolean = false): Result<Identity> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "📡 Request: POST /api/auth/register")
                Log.d(TAG, "📦 deviceId: $deviceId")
                
                val request = CreateIdentityRequest(
                    deviceId = deviceId,
                    publicKey = "dummy_key_${System.currentTimeMillis()}"
                )
                
                Log.d(TAG, "� Request object: deviceId=${request.deviceId}, publicKey=${request.publicKey}")
                
                val response = api.register(request)
                
                if (response.isSuccessful && response.body() != null) {
                    val authResponse = response.body()!!
                    Log.d(TAG, "📥 Response: ${response.code()}")
                    Log.d(TAG, "✅ Registration successful: ${authResponse.identity.username}")
                    Result.success(authResponse.identity)
                } else {
                    val errorBody = response.errorBody()?.string() ?: "Unknown error"
                    Log.e(TAG, "❌ Failed to register: ${response.code()}")
                    Log.e(TAG, "Error body: $errorBody")
                    Result.failure(Exception("Failed to register: ${response.code()}"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Registration error: ${e.message}", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun getIdentity(id: String): Result<Identity> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Getting identity: $id")
                val response = api.getIdentity(id)
                if (response.isSuccessful && response.body() != null) {
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to get identity"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error getting identity", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun updateIdentity(id: String, username: String? = null, bio: String? = null, avatar: String? = null): Result<Identity> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Updating identity: $id")
                val response = api.updateIdentity(id, UpdateIdentityRequest(username, bio, avatar))
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Identity updated")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to update identity"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating identity", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun checkUsername(username: String): Result<Boolean> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Checking username: $username")
                val response = api.checkUsername(username)
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Username available: ${response.body()?.available}")
                    Result.success(response.body()!!.available)
                } else {
                    Result.failure(Exception("Failed to check username"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking username", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun updateProfile(identityId: String, username: String? = null, bio: String? = null, avatar: String? = null): Result<Identity> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Updating profile for: $identityId")
                if (avatar != null) {
                    Log.d(TAG, "Avatar included, size: ${avatar.length} chars")
                }
                val response = api.updateProfile(UpdateProfileRequest(identityId, username, bio, avatar))
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Profile updated: ${response.body()?.username}")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to update profile"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating profile", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun deleteIdentity(id: String): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Deleting identity: $id")
                val response = api.deleteIdentity(id)
                if (response.isSuccessful) {
                    Log.d(TAG, "Identity deleted")
                    Result.success(Unit)
                } else {
                    Result.failure(Exception("Failed to delete identity"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error deleting identity", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun getChats(identityId: String): Result<List<Chat>> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "📡 Request: GET /chats?identity_id=$identityId")
                val response = api.getChats(identityId)
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "📥 Chats loaded: ${response.body()?.size}")
                    Result.success(response.body()!!)
                } else {
                    val errorBody = response.errorBody()?.string() ?: "Unknown error"
                    Log.e(TAG, "❌ Failed to get chats: ${response.code()}")
                    Log.e(TAG, "Error body: $errorBody")
                    Result.failure(Exception("Failed to get chats: ${response.code()}"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error getting chats", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun startChat(participantId: String): Result<Chat> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Starting chat with: $participantId")
                val response = api.startChat(CreateChatRequest(participantId))
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Chat started: ${response.body()?.id}")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to start chat"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error starting chat", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun startChatByToken(token: String): Result<Chat> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Starting chat by token: $token")
                val response = api.startChatByToken(StartChatByTokenRequest(token))
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Chat started by token: ${response.body()?.id}")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to start chat by token"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error starting chat by token", e)
                Result.failure(e)
            }
        }
    }
    
    // Message operations
    suspend fun getMessages(chatId: String): Result<List<Message>> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Getting messages for chat: $chatId")
                val response = api.getMessages(chatId)
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Messages loaded: ${response.body()?.size}")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to get messages"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error getting messages", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun sendMessage(chatId: String, senderIdentityId: String, text: String): Result<Message> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Sending message to chat: $chatId")
                val response = api.sendMessage(SendMessageRequest(chatId, senderIdentityId, text))
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Message sent: ${response.body()?.id}")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to send message"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error sending message", e)
                Result.failure(e)
            }
        }
    }
    
    // Invite operations
    suspend fun generateInviteLink(identityId: String): Result<InviteLink> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Generating invite link for: $identityId")
                val response = api.generateInviteLink(GenerateInviteLinkRequest(identityId))
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Invite link generated: ${response.body()?.url}")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to generate invite link"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error generating invite link", e)
                Result.failure(e)
            }
        }
    }
    
    // Search operations
    suspend fun searchByUsername(username: String): Result<Identity> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Searching for username: $username")
                val response = api.searchByUsername(username)
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "User found: ${response.body()?.username}")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("User not found"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error searching user", e)
                Result.failure(e)
            }
        }
    }
    
    // Direct chat operations
    suspend fun startDirectChat(myIdentityId: String, otherIdentityId: String): Result<ChatStartResponse> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Starting direct chat")
                val response = api.startDirectChat(
                    StartDirectChatRequest(myIdentityId, otherIdentityId)
                )
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Direct chat created: ${response.body()?.chatId}")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to start direct chat"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error starting direct chat", e)
                Result.failure(e)
            }
        }
    }
    
    // Start chat by invite token
    suspend fun startChatByInvite(token: String, myIdentityId: String): Result<ChatStartResponse> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Starting chat by invite token")
                val response = api.startChatByInvite(
                    StartChatByInviteRequest(token, myIdentityId)
                )
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Chat created by invite: ${response.body()?.chatId}")
                    Result.success(response.body()!!)
                } else {
                    Result.failure(Exception("Failed to start chat by invite"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error starting chat by invite", e)
                Result.failure(e)
            }
        }
    }
    
    // Invite link preview
    suspend fun previewInviteLink(token: String): Result<Identity> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Previewing invite link: $token")
                val response = api.previewInviteLink(token)
                
                Log.d(TAG, "Response code: ${response.code()}")
                Log.d(TAG, "Response successful: ${response.isSuccessful}")
                
                if (response.isSuccessful && response.body() != null) {
                    val body = response.body()!!
                    Log.d(TAG, "Raw response body: $body")
                    Log.d(TAG, "Invite preview loaded: ${body.identity.username}")
                    Result.success(body.identity)
                } else {
                    val errorMsg = "Failed to preview invite: code=${response.code()}"
                    val errorBody = response.errorBody()?.string()
                    Log.e(TAG, "$errorMsg, error: $errorBody")
                    Result.failure(Exception(errorMsg))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error previewing invite", e)
                // Print full JSON response for debugging
                Log.e(TAG, "Exception type: ${e.javaClass.simpleName}")
                Log.e(TAG, "Exception message: ${e.message}")
                Result.failure(e)
            }
        }
    }
    
    suspend fun consumeInviteLink(token: String): Result<Identity> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Consuming invite link: $token")
                val response = api.consumeInviteLink(token)
                if (response.isSuccessful && response.body() != null) {
                    Log.d(TAG, "Invite consumed")
                    Result.success(response.body()!!.identity)
                } else {
                    Result.failure(Exception("Failed to consume invite"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error consuming invite", e)
                Result.failure(e)
            }
        }
    }
    
    // Delete chat
    suspend fun deleteChat(chatId: String): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Deleting chat: $chatId")
                val response = api.deleteChat(chatId)
                if (response.isSuccessful) {
                    Log.d(TAG, "Chat deleted successfully")
                    Result.success(Unit)
                } else {
                    Result.failure(Exception("Failed to delete chat"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error deleting chat", e)
                Result.failure(e)
            }
        }
    }
    
    // Pin/Unpin chat
    suspend fun togglePinChat(chatId: String, currentUserId: String, isPinned: Boolean): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Toggling pin for chat: $chatId, isPinned: $isPinned")
                val response = api.togglePinChat(
                    chatId,
                    PinChatRequest(currentUserId, !isPinned)
                )
                if (response.isSuccessful) {
                    Log.d(TAG, "Chat pin toggled successfully")
                    Result.success(Unit)
                } else {
                    Result.failure(Exception("Failed to toggle pin"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error toggling pin", e)
                Result.failure(e)
            }
        }
    }
    
    // Get user status
    suspend fun getUserStatus(identityId: String): Result<Pair<Boolean, Long>> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Getting user status: $identityId")
                val response = api.getUserStatus(identityId)
                if (response.isSuccessful && response.body() != null) {
                    val status = response.body()!!
                    Log.d(TAG, "User status: online=${status.online}, lastSeen=${status.last_seen}")
                    Result.success(Pair(status.online, status.last_seen))
                } else {
                    Result.failure(Exception("Failed to get user status"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error getting user status", e)
                Result.failure(e)
            }
        }
    }
}
