package com.bananjemmy.data.api

import com.bananjemmy.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface JemmyApiService {
    
    // Auth endpoints
    @POST("api/auth/register")
    suspend fun register(@Body request: CreateIdentityRequest): Response<AuthResponse>
    
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
    @GET("api/identity/search")
    suspend fun searchByUsername(@Query("tag") tag: String): Response<List<Identity>>
    
    // Direct chat
    @POST("api/chat/direct")
    suspend fun startDirectChat(@Body request: StartDirectChatRequest): Response<ChatStartResponse>
}
