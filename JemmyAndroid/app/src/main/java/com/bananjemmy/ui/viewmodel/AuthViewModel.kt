package com.bananjemmy.ui.viewmodel

import android.content.Context
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bananjemmy.data.model.Identity
import com.bananjemmy.data.repository.JemmyRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

sealed class AuthState {
    object Loading : AuthState()
    object Unauthenticated : AuthState()
    data class Authenticated(val identity: Identity) : AuthState()
    data class Error(val message: String) : AuthState()
}

class AuthViewModel : ViewModel() {
    private val repository = JemmyRepository()
    private val TAG = "AuthViewModel"
    private var appContext: Context? = null
    
    private val _authState = MutableStateFlow<AuthState>(AuthState.Loading)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    fun checkAuth(context: Context) {
        appContext = context.applicationContext
        viewModelScope.launch {
            _isLoading.value = true
            val prefs = context.getSharedPreferences("jemmy_prefs", Context.MODE_PRIVATE)
            val identityId = prefs.getString("identity_id", null)
            
            if (identityId != null) {
                Log.d(TAG, "Found saved identity: $identityId")
                
                // Сначала пытаемся загрузить из кеша
                val cachedUsername = prefs.getString("identity_username", null)
                val cachedBio = prefs.getString("identity_bio", null)
                
                if (cachedUsername != null) {
                    Log.d(TAG, "📦 Loading identity from cache: $cachedUsername")
                    val cachedIdentity = Identity(
                        _id = identityId,
                        username = cachedUsername,
                        bio = cachedBio ?: ""
                    )
                    _authState.value = AuthState.Authenticated(cachedIdentity)
                    _isLoading.value = false
                    
                    // Пытаемся обновить с сервера в фоне
                    loadIdentityFromServer(identityId, silent = true)
                } else {
                    // Нет кеша, загружаем с сервера
                    loadIdentityFromServer(identityId, silent = false)
                }
            } else {
                Log.d(TAG, "No saved identity found")
                _authState.value = AuthState.Unauthenticated
                _isLoading.value = false
            }
        }
    }
    
    private suspend fun loadIdentityFromServer(id: String, silent: Boolean) {
        repository.getIdentity(id).fold(
            onSuccess = { identity ->
                Log.d(TAG, "✅ Identity loaded from server: ${identity.username}")
                _authState.value = AuthState.Authenticated(identity)
                if (!silent) {
                    _isLoading.value = false
                }
                
                // Сохраняем в кеш
                appContext?.let { ctx ->
                    val prefs = ctx.getSharedPreferences("jemmy_prefs", Context.MODE_PRIVATE)
                    prefs.edit().apply {
                        putString("identity_username", identity.username)
                        putString("identity_bio", identity.bio)
                        apply()
                    }
                    Log.d(TAG, "💾 Identity cached")
                }
            },
            onFailure = { error ->
                Log.e(TAG, "❌ Failed to load identity from server: ${error.message}")
                if (!silent) {
                    // Если не silent и нет кеша - показываем ошибку
                    val currentState = _authState.value
                    if (currentState !is AuthState.Authenticated) {
                        _authState.value = AuthState.Error(error.message ?: "Unknown error")
                    }
                    _isLoading.value = false
                }
                // Если silent - игнорируем ошибку, используем кеш
            }
        )
    }
    
    private suspend fun loadIdentity(id: String) {
        loadIdentityFromServer(id, silent = false)
    }
    
    fun createIdentity(context: Context) {
        viewModelScope.launch {
            _isLoading.value = true
            Log.d(TAG, "📱 Creating identity with auto-generated username")
            
            // Generate device ID if not exists
            val prefs = context.getSharedPreferences("jemmy_prefs", Context.MODE_PRIVATE)
            val deviceId = prefs.getString("device_id", null) ?: UUID.randomUUID().toString().also {
                prefs.edit().putString("device_id", it).apply()
                Log.d(TAG, "🔑 Generated new device ID: $it")
            }
            
            repository.createIdentity(deviceId, false).fold(
                onSuccess = { identity ->
                    Log.d(TAG, "✅ Identity created: ${identity.username} (${identity.id})")
                    saveIdentity(context, identity)
                    _authState.value = AuthState.Authenticated(identity)
                    _isLoading.value = false
                },
                onFailure = { error ->
                    Log.e(TAG, "❌ Failed to create identity", error)
                    _authState.value = AuthState.Error(error.message ?: "Failed to create identity")
                    _isLoading.value = false
                }
            )
        }
    }
    
    fun updateIdentity(context: Context, username: String? = null, bio: String? = null, avatar: String? = null) {
        viewModelScope.launch {
            val currentState = _authState.value
            if (currentState is AuthState.Authenticated) {
                _isLoading.value = true
                Log.d(TAG, "Updating identity: ${currentState.identity.id}")
                
                repository.updateIdentity(currentState.identity.id, username, bio, avatar).fold(
                    onSuccess = { identity ->
                        Log.d(TAG, "Identity updated successfully")
                        _authState.value = AuthState.Authenticated(identity)
                        _isLoading.value = false
                    },
                    onFailure = { error ->
                        Log.e(TAG, "Failed to update identity", error)
                        _authState.value = AuthState.Error(error.message ?: "Failed to update identity")
                        _isLoading.value = false
                    }
                )
            }
        }
    }
    
    fun deleteIdentity(context: Context) {
        viewModelScope.launch {
            val currentState = _authState.value
            if (currentState is AuthState.Authenticated) {
                _isLoading.value = true
                Log.d(TAG, "Deleting identity: ${currentState.identity.id}")
                
                repository.deleteIdentity(currentState.identity.id).fold(
                    onSuccess = {
                        Log.d(TAG, "Identity deleted successfully")
                        clearIdentityId(context)
                        _authState.value = AuthState.Unauthenticated
                        _isLoading.value = false
                    },
                    onFailure = { error ->
                        Log.e(TAG, "Failed to delete identity", error)
                        _authState.value = AuthState.Error(error.message ?: "Failed to delete identity")
                        _isLoading.value = false
                    }
                )
            }
        }
    }
    
    fun logout(context: Context) {
        Log.d(TAG, "Logging out")
        clearIdentityId(context)
        _authState.value = AuthState.Unauthenticated
    }
    
    fun updateLocalIdentity(identity: Identity) {
        Log.d(TAG, "Updating local identity: ${identity.username}")
        _authState.value = AuthState.Authenticated(identity)
    }
    
    private fun saveIdentity(context: Context, identity: Identity) {
        val prefs = context.getSharedPreferences("jemmy_prefs", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString("identity_id", identity.id)
            putString("identity_username", identity.username)
            putString("identity_bio", identity.bio)
            apply()
        }
        Log.d(TAG, "💾 Identity saved: ${identity.username}")
    }
    
    private fun saveIdentityId(context: Context, id: String) {
        val prefs = context.getSharedPreferences("jemmy_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("identity_id", id).apply()
        Log.d(TAG, "💾 Identity ID saved: $id")
    }
    
    private fun clearIdentityId(context: Context) {
        val prefs = context.getSharedPreferences("jemmy_prefs", Context.MODE_PRIVATE)
        prefs.edit().apply {
            remove("identity_id")
            remove("identity_username")
            remove("identity_bio")
            apply()
        }
        Log.d(TAG, "Identity cleared")
    }
}
