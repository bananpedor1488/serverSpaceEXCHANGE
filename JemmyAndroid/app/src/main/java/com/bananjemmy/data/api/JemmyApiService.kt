package com.bananjemmy.data.api

import com.bananjemmy.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface JemmyApiService {
    
    // Auth endpoints
    @POST("api/auth/register")
    suspend fun register(@Body request: CreateIdentityRequest): Response<AuthResponse>
    
    @GET("api/auth/check-device/{deviceId}")
    suspend fun checkDevice(@Path("deviceId") deviceId: String): Response<DeviceCheckResponse>
    
    // Identity endpoints
    @GET("api/identity/check-username/{username}")
    suspend fun checkUsername(@Path("username") username: String): Response<UsernameCheckResponse>
    
    @POST("api/identity/update")
    suspend fun updateProfile(@Body request: UpdateProfileRequest): Response<Identity>
    
    @GET("api/identity/{id}")
    suspend fun getIdentity(@Path("id") id: String): Response<Identity>
    
    @PUT("api/identity/{id}")
    suspend fun updateIdentity(
        @Path("id") id: String,
        @Body request: UpdateIdentityRequest
    ): Response<Identity>
    
    @DELETE("api/identity/{id}")
    suspend fun deleteIdentity(@Path("id") id: String): Response<Unit>
    
    // Account deletion
    @POST("api/account/delete")
    suspend fun deleteAccount(@Body request: DeleteAccountRequest): Response<DeleteAccountResponse>
    
    // Chat endpoints
    @GET("api/chats")
    suspend fun getChats(@Query("identity_id") identityId: String): Response<List<Chat>>
    
    @POST("api/chat/start")
    suspend fun startChat(@Body request: CreateChatRequest): Response<Chat>
    
    @POST("api/chat/start-by-token")
    suspend fun startChatByToken(@Body request: StartChatByTokenRequest): Response<Chat>
    
    @GET("api/chat/{id}")
    suspend fun getChat(@Path("id") id: String): Response<Chat>
    
    // Message endpoints
    @GET("api/messages")
    suspend fun getMessages(@Query("chat_id") chatId: String): Response<List<Message>>
    
    @POST("api/message")
    suspend fun sendMessage(@Body request: SendMessageRequest): Response<Message>
    
    // Invite endpoints
    @POST("api/identity/generate-link")
    suspend fun generateInviteLink(@Body request: GenerateInviteLinkRequest): Response<InviteLink>
    
    @GET("api/invite/preview/{token}")
    suspend fun previewInviteLink(@Path("token") token: String): Response<InviteLinkPreview>
    
    @GET("api/invite/{token}")
    suspend fun consumeInviteLink(@Path("token") token: String): Response<InviteLinkPreview>
    
    // Search endpoints
    @GET("api/identity/search/{username}")
    suspend fun searchByUsername(@Path("username") username: String): Response<Identity>
    
    // Direct chat
    @POST("api/chat/direct")
    suspend fun startDirectChat(@Body request: StartDirectChatRequest): Response<ChatStartResponse>
    
    // Start chat by invite token
    @POST("api/chat/start")
    suspend fun startChatByInvite(@Body request: StartChatByInviteRequest): Response<ChatStartResponse>
    
    // Delete chat
    @DELETE("api/chat/{id}")
    suspend fun deleteChat(@Path("id") chatId: String): Response<Unit>
    
    // Pin chat
    @PATCH("api/chat/{id}/pin")
    suspend fun togglePinChat(
        @Path("id") chatId: String,
        @Body request: PinChatRequest
    ): Response<PinChatResponse>
    
    // Mute chat
    @PATCH("api/chat/{id}/mute")
    suspend fun toggleMuteChat(
        @Path("id") chatId: String,
        @Body request: MuteChatRequest
    ): Response<MuteChatResponse>
    
    // User status
    @GET("api/user/status/{identity_id}")
    suspend fun getUserStatus(@Path("identity_id") identityId: String): Response<UserStatusResponse>
    
    // Privacy settings endpoints
    @GET("api/identity/privacy/{identity_id}")
    suspend fun getPrivacySettings(@Path("identity_id") identityId: String): Response<PrivacySettingsResponse>
    
    @PATCH("api/identity/privacy/update")
    suspend fun updatePrivacySettings(@Body request: UpdatePrivacySettingsRequest): Response<UpdatePrivacySettingsResponse>
}

data class UserStatusResponse(
    val identity_id: String,
    val online: Boolean,
    val last_seen: Long
)

data class PinChatRequest(
    val identity_id: String,
    val is_pinned: Boolean
)

data class PinChatResponse(
    val is_pinned: Boolean
)

data class MuteChatRequest(
    val identity_id: String,
    val is_muted: Boolean
)

data class MuteChatResponse(
    val is_muted: Boolean
)

data class DeleteAccountRequest(
    val device_id: String
)

data class DeleteAccountResponse(
    val success: Boolean,
    val message: String
)
