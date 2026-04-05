package com.bananjemmy

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.flow.first
import com.bananjemmy.data.model.Chat
import com.bananjemmy.data.model.Identity
import com.bananjemmy.data.repository.JemmyRepository
import com.bananjemmy.ui.screen.BlockedUsersScreen
import com.bananjemmy.ui.screen.ChatListScreen
import com.bananjemmy.ui.screen.ChatScreen
import com.bananjemmy.ui.screen.DataStorageScreen
import com.bananjemmy.ui.screen.InviteProfileScreen
import com.bananjemmy.ui.screen.LinkGeneratorScreen
import com.bananjemmy.ui.screen.OnboardingScreen
import com.bananjemmy.ui.screen.PrivacySettingsScreen
import com.bananjemmy.ui.screen.ProfileEditScreen
import com.bananjemmy.ui.screen.ProfileScreen
import com.bananjemmy.ui.screen.SearchScreen
import com.bananjemmy.ui.theme.JemmyTheme
import com.bananjemmy.ui.viewmodel.AuthState
import com.bananjemmy.ui.viewmodel.AuthViewModel
import com.bananjemmy.ui.viewmodel.ChatViewModel

class MainActivity : ComponentActivity() {
    private val authViewModel: AuthViewModel by viewModels()
    private lateinit var chatViewModel: ChatViewModel
    private lateinit var cacheManager: com.bananjemmy.data.cache.CacheManager
    private lateinit var pinnedChatsManager: com.bananjemmy.data.cache.PinnedChatsManager
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("MainActivity", "🚀 onCreate started")
        
        // Initialize cache manager
        cacheManager = com.bananjemmy.data.cache.CacheManager(this)
        Log.d("MainActivity", "✅ CacheManager created: $cacheManager")
        
        // Initialize pinned chats manager
        pinnedChatsManager = com.bananjemmy.data.cache.PinnedChatsManager(this)
        Log.d("MainActivity", "✅ PinnedChatsManager created")
        
        chatViewModel = ChatViewModel(cacheManager, pinnedChatsManager)
        Log.d("MainActivity", "✅ ChatViewModel created with CacheManager and PinnedChatsManager")
        
        // Check auth on start
        authViewModel.checkAuth(this)
        
        // Handle deep link - extract token
        val deepLinkToken = extractTokenFromIntent(intent)
        if (deepLinkToken != null) {
            Log.d("MainActivity", "🔗 Deep link token found in onCreate: $deepLinkToken")
        }
        
        enableEdgeToEdge()
        setContent {
            // Сохраняем токен в State чтобы он был доступен в Compose
            var pendingToken by remember { mutableStateOf(deepLinkToken) }
            
            JemmyTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    JemmyApp(
                        authViewModel = authViewModel,
                        chatViewModel = chatViewModel,
                        cacheManager = cacheManager,
                        onProcessDeepLink = { token ->
                            processDeepLinkToken(token)
                        }
                    )
                    
                    // Process pending deep link when authenticated
                    val authState by authViewModel.authState.collectAsStateWithLifecycle()
                    LaunchedEffect(authState, pendingToken) {
                        Log.d("MainActivity", "🔄 LaunchedEffect triggered")
                        Log.d("MainActivity", "   authState: ${authState::class.simpleName}")
                        Log.d("MainActivity", "   pendingToken: $pendingToken")
                        
                        if (authState is AuthState.Authenticated && pendingToken != null) {
                            val token = pendingToken!!
                            Log.d("MainActivity", "🔗 Processing pending deep link after auth: $token")
                            processDeepLinkToken(token)
                            pendingToken = null
                        }
                    }
                }
            }
        }
    }
    
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Блокируем кнопку "Назад" - ничего не делаем
        // Пользователь не может выйти из приложения кнопкой назад
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val token = extractTokenFromIntent(intent)
        
        if (token != null) {
            Log.d("MainActivity", "🔗 New intent with token: $token")
            // If already authenticated, process immediately
            val authState = authViewModel.authState.value
            if (authState is AuthState.Authenticated) {
                Log.d("MainActivity", "✅ Already authenticated, processing immediately")
                processDeepLinkToken(token)
            } else {
                Log.d("MainActivity", "⏳ Not authenticated yet, will process after auth")
                // Token will be processed by LaunchedEffect after auth
            }
        }
    }
    
    private fun extractTokenFromIntent(intent: Intent?): String? {
        val data: Uri? = intent?.data
        return data?.let { uri ->
            Log.d("MainActivity", "🔗 Deep link received: $uri")
            Log.d("MainActivity", "🔗 Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}")
            Log.d("MainActivity", "🔗 Path segments: ${uri.pathSegments}")
            
            when {
                // jemmy://invite/{token}
                uri.scheme == "jemmy" && uri.host == "invite" -> {
                    val t = uri.lastPathSegment
                    Log.d("MainActivity", "✅ Extracted token from jemmy:// scheme: $t")
                    t
                }
                // https://weeky-six.vercel.app/api/u/{token}
                uri.scheme == "https" && uri.pathSegments.contains("u") -> {
                    val t = uri.lastPathSegment
                    Log.d("MainActivity", "✅ Extracted token from HTTPS link: $t")
                    t
                }
                else -> {
                    Log.d("MainActivity", "⚠️ Unknown deep link format")
                    null
                }
            }
        } ?: run {
            Log.d("MainActivity", "⚠️ No deep link data in intent")
            null
        }
    }
    
    private fun processDeepLinkToken(token: String) {
        Log.d("MainActivity", "✅ Processing deep link token: $token")
        
        // Show toast for debugging
        runOnUiThread {
            android.widget.Toast.makeText(
                this,
                "🔗 Processing invite: $token",
                android.widget.Toast.LENGTH_LONG
            ).show()
        }
        
        val repository = JemmyRepository()
        lifecycleScope.launch {
            Log.d("MainActivity", "📡 Calling previewInviteLink API...")
            val result = repository.previewInviteLink(token)
            result.onSuccess { identity ->
                Log.d("MainActivity", "✅ Invite preview loaded: ${identity.username}")
                Log.d("MainActivity", "🎯 Setting pendingInvite in ViewModel")
                
                runOnUiThread {
                    android.widget.Toast.makeText(
                        this@MainActivity,
                        "✅ Loaded: ${identity.username}",
                        android.widget.Toast.LENGTH_SHORT
                    ).show()
                }
                
                chatViewModel.setPendingInvite(identity, token)
                Log.d("MainActivity", "✅ pendingInvite set successfully")
            }.onFailure {
                Log.e("MainActivity", "❌ Failed to load invite preview: ${it.message}", it)
                
                runOnUiThread {
                    android.widget.Toast.makeText(
                        this@MainActivity,
                        "❌ Error: ${it.message}",
                        android.widget.Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d("MainActivity", "🔌 onDestroy - disconnecting WebSocket")
        chatViewModel.disconnectWebSocket()
    }
}

@Composable
fun JemmyApp(
    authViewModel: AuthViewModel,
    chatViewModel: ChatViewModel,
    cacheManager: com.bananjemmy.data.cache.CacheManager,
    onProcessDeepLink: (String) -> Unit
) {
    val authState by authViewModel.authState.collectAsStateWithLifecycle()
    
    when (val state = authState) {
        is AuthState.Loading -> {
            // Loading screen
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                    modifier = Modifier.padding(32.dp)
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(48.dp),
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Загрузка...",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
                    )
                }
            }
        }
        
        is AuthState.Unauthenticated -> {
            val context = androidx.compose.ui.platform.LocalContext.current
            OnboardingScreen(
                onCreateIdentity = { ephemeral ->
                    authViewModel.createIdentity(context)
                }
            )
        }
        
        is AuthState.Error -> {
            // Custom styled error dialog
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.7f)),
                contentAlignment = Alignment.Center
            ) {
                Card(
                    modifier = Modifier
                        .padding(32.dp)
                        .fillMaxWidth(),
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    ),
                    elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Warning icon
                        Icon(
                            imageVector = Icons.Filled.Warning,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = Color(0xFFFF9800)
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Title
                        Text(
                            text = "Подозрение",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        // Message
                        Text(
                            text = "Незарегистрированный аккаунт.\n\nАккаунт был удален или не существует.\n\nВыполняем выход из системы.",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f),
                            textAlign = TextAlign.Center,
                            lineHeight = 24.sp
                        )
                        
                        Spacer(modifier = Modifier.height(24.dp))
                        
                        // OK button
                        Button(
                            onClick = { authViewModel.dismissError() },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(56.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary
                            )
                        ) {
                            Text(
                                text = "Понятно",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold
                            )
                        }
                    }
                }
            }
        }
        
        is AuthState.AccountFound -> {
            val context = androidx.compose.ui.platform.LocalContext.current
            OnboardingScreen(
                onCreateIdentity = { ephemeral ->
                    authViewModel.createIdentity(context)
                },
                onRestoreAccount = {
                    authViewModel.restoreAccount(context, state.identity, state.userId)
                },
                existingAccount = state.identity
            )
        }
        
        is AuthState.Authenticated -> {
            val identity = state.identity
            
            // Load chats when authenticated
            LaunchedEffect(identity.id) {
                Log.d("MainActivity", "📡 Loading chats for identity: ${identity.id}")
                chatViewModel.loadChats(identity.id)
                chatViewModel.connectWebSocket(identity.id, identity.id)
                
                // Start periodic account check
                authViewModel.startPeriodicAccountCheck()
            }
            
            DisposableEffect(Unit) {
                onDispose {
                    chatViewModel.disconnectWebSocket()
                    authViewModel.stopPeriodicAccountCheck()
                }
            }
            
            MainScreen(
                identity = identity,
                chatViewModel = chatViewModel,
                authViewModel = authViewModel,
                cacheManager = cacheManager
            )
        }
        
        is AuthState.Error -> {
            // Error screen
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.error
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Ошибка",
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.error
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = state.message,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
fun MainScreen(
    identity: Identity,
    chatViewModel: ChatViewModel,
    authViewModel: AuthViewModel,
    cacheManager: com.bananjemmy.data.cache.CacheManager
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    var selectedTab by remember { mutableIntStateOf(0) }
    var showLinkGenerator by remember { mutableStateOf(false) }
    var showSearch by remember { mutableStateOf(false) }
    var showEditProfile by remember { mutableStateOf(false) }
    var showDataStorage by remember { mutableStateOf(false) }
    var showPrivacySettings by remember { mutableStateOf(false) }
    var showBlockedUsers by remember { mutableStateOf(false) }
    var selectedChat by remember { mutableStateOf<Chat?>(null) }
    
    // Получаем pendingInvite из ViewModel
    val pendingInvite by chatViewModel.pendingInvite.collectAsStateWithLifecycle()
    
    // Логируем изменения pendingInvite
    LaunchedEffect(pendingInvite) {
        Log.d("MainScreen", "🔔 pendingInvite changed: ${pendingInvite != null}")
        if (pendingInvite != null) {
            Log.d("MainScreen", "   Identity: ${pendingInvite?.first?.username}")
            Log.d("MainScreen", "   Token: ${pendingInvite?.second}")
        }
    }
    
    // Скрываем таббар когда открыт чат или поиск
    val showBottomBar = selectedChat == null && !showSearch
    
    Scaffold(
        modifier = Modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets.systemBars,
        bottomBar = {
            androidx.compose.animation.AnimatedVisibility(
                visible = showBottomBar,
                enter = androidx.compose.animation.fadeIn() + androidx.compose.animation.expandVertically(),
                exit = androidx.compose.animation.fadeOut() + androidx.compose.animation.shrinkVertically()
            ) {
                NavigationBar(
                    containerColor = MaterialTheme.colorScheme.surface,
                    tonalElevation = 8.dp
                ) {
                    NavigationBarItem(
                        icon = {
                            Icon(
                                imageVector = if (selectedTab == 0) Icons.Filled.Email else Icons.Outlined.Email,
                                contentDescription = "Чаты"
                            )
                        },
                        label = { Text("Чаты") },
                        selected = selectedTab == 0,
                        onClick = { selectedTab = 0 }
                    )
                    
                    NavigationBarItem(
                        icon = {
                            Icon(
                                imageVector = if (selectedTab == 1) Icons.Filled.Person else Icons.Outlined.Person,
                                contentDescription = "Профиль"
                            )
                        },
                        label = { Text("Профиль") },
                        selected = selectedTab == 1,
                        onClick = { selectedTab = 1 }
                    )
                }
            }
        }
    ) { paddingValues ->
        // Полноэкранный экран поиска
        if (showSearch) {
            SearchScreen(
                onSearch = { username ->
                    val repository = com.bananjemmy.data.repository.JemmyRepository()
                    repository.searchByUsername(username, identity.id)
                },
                onStartChat = { foundIdentity ->
                    val repository = com.bananjemmy.data.repository.JemmyRepository()
                    val result = repository.startDirectChat(identity.id, foundIdentity.id)
                    result.map { it.chatId }
                },
                onDismiss = { showSearch = false },
                onChatCreated = { chatId ->
                    Log.d("MainActivity", "Chat created: $chatId, opening chat...")
                    // Закрываем поиск
                    showSearch = false
                    // Переключаемся на вкладку чатов
                    selectedTab = 0
                    // Загружаем чаты и открываем созданный
                    kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main).launch {
                        // Загружаем чаты
                        chatViewModel.loadChats(identity.id)
                        
                        // Ждем пока состояние обновится до Success
                        val state = chatViewModel.chatListState.first { it is com.bananjemmy.ui.viewmodel.ChatListState.Success }
                        if (state is com.bananjemmy.ui.viewmodel.ChatListState.Success) {
                            // Находим созданный чат
                            val chat = state.chats.find { it.id == chatId }
                            if (chat != null) {
                                selectedChat = chat
                                Log.d("MainActivity", "Opened chat with ${chat.user.username}")
                            } else {
                                Log.w("MainActivity", "Chat $chatId not found in loaded chats")
                            }
                        }
                    }
                },
                cacheManager = cacheManager
            )
        } else {
            androidx.compose.animation.Crossfade(
                targetState = selectedChat,
                animationSpec = androidx.compose.animation.core.tween(300)
            ) { chat ->
                if (chat != null) {
                    ChatScreen(
                        chatId = chat.id,
                        otherUser = chat.user,
                        currentUserId = identity.id,
                        chatViewModel = chatViewModel,
                        onBack = { 
                            selectedChat = null 
                        },
                        isOnline = chat.isOnline ?: false,
                        lastSeen = chat.lastSeen ?: 0L,
                        cacheManager = cacheManager
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(paddingValues)
                    ) {
                        when (selectedTab) {
                            0 -> {
                                val chatListState by chatViewModel.chatListState.collectAsStateWithLifecycle()
                                
                                // Автообновление при возврате на вкладку чатов
                                LaunchedEffect(selectedTab) {
                                    if (selectedTab == 0) {
                                        chatViewModel.loadChats(identity.id)
                                    }
                                }
                                
                                // Polling для списка чатов каждые 0.5 секунды (теперь с кешем статусов)
                                LaunchedEffect(selectedTab) {
                                    if (selectedTab == 0) {
                                        while (true) {
                                            kotlinx.coroutines.delay(500)
                                            chatViewModel.refreshChats(identity.id)
                                        }
                                    }
                                }
                                
                                val isRefreshing by chatViewModel.isRefreshing.collectAsStateWithLifecycle()
                                
                                ChatListScreen(
                                    chatListState = chatListState,
                                    currentUserId = identity.id,
                                    onChatClick = { selectedChat = it },
                                    onRefresh = {
                                        chatViewModel.loadChats(identity.id)
                                    },
                                    isRefreshing = isRefreshing,
                                    onSearchClick = { showSearch = true },
                                    cacheManager = cacheManager,
                                    chatViewModel = chatViewModel
                                )
                            }
                            1 -> {
                                ProfileScreen(
                                    identity = identity,
                                    authViewModel = authViewModel,
                                    onNavigateToLinkGenerator = { showLinkGenerator = true },
                                    onNavigateToSearch = { showSearch = true },
                                    onNavigateToEdit = { showEditProfile = true },
                                    onNavigateToDataStorage = { showDataStorage = true },
                                    onNavigateToPrivacy = { showPrivacySettings = true },
                                    cacheManager = cacheManager
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Link Generator Dialog
    if (showLinkGenerator) {
        Dialog(onDismissRequest = { showLinkGenerator = false }) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                LinkGeneratorScreen(
                    identityId = identity.id,
                    onGenerateLink = {
                        val repository = com.bananjemmy.data.repository.JemmyRepository()
                        val result = repository.generateInviteLink(identity.id)
                        result.map { it.url }
                    },
                    onDismiss = { showLinkGenerator = false }
                )
            }
        }
    }
    
    // Edit Profile Dialog
    if (showEditProfile) {
        val activityContext = context as? android.app.Activity
        Dialog(onDismissRequest = { showEditProfile = false }) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                ProfileEditScreen(
                    identity = identity,
                    onCheckUsername = { username ->
                        runBlocking {
                            val repository = com.bananjemmy.data.repository.JemmyRepository()
                            repository.checkUsername(username)
                        }
                    },
                    onSave = { username, bio, avatar ->
                        runBlocking {
                            val repository = com.bananjemmy.data.repository.JemmyRepository()
                            val result = repository.updateProfile(identity.id, username, bio, avatar)
                            result.onSuccess { updatedIdentity ->
                                authViewModel.updateLocalIdentity(updatedIdentity)
                                
                                // Save avatar to cache if updated
                                if (avatar != null && updatedIdentity.avatarUpdatedAt != null) {
                                    try {
                                        // Parse ISO date string or timestamp
                                        val timestamp = updatedIdentity.avatarUpdatedAt.toLongOrNull() 
                                            ?: java.time.Instant.parse(updatedIdentity.avatarUpdatedAt).toEpochMilli()
                                        cacheManager.saveAvatar(identity.id, avatar, timestamp)
                                    } catch (e: Exception) {
                                        Log.e("MainActivity", "Failed to parse avatar timestamp", e)
                                    }
                                }
                            }.onFailure { error ->
                                // Check if identity not found - logout user
                                if (error is com.bananjemmy.data.repository.JemmyRepository.IdentityNotFoundException) {
                                    Log.e("MainActivity", "🚨 Identity not found - logging out user")
                                    
                                    // Show toast on main thread
                                    activityContext?.runOnUiThread {
                                        android.widget.Toast.makeText(
                                            activityContext,
                                            "Аккаунт не найден. Выход из системы...",
                                            android.widget.Toast.LENGTH_LONG
                                        ).show()
                                    }
                                    
                                    // Logout and clear all data
                                    activityContext?.let { authViewModel.logout(it) }
                                    chatViewModel.disconnectWebSocket()
                                    cacheManager.clearAllCache()
                                    showEditProfile = false
                                }
                            }
                            result
                        }
                    },
                    onDismiss = { showEditProfile = false }
                )
            }
        }
    }
    
    // Data Storage Dialog
    if (showDataStorage) {
        var cacheStats by remember { mutableStateOf(com.bananjemmy.data.cache.CacheStats(0, 0, 0, 0.0)) }
        var isClearing by remember { mutableStateOf(false) }
        val scope = rememberCoroutineScope()
        
        // Обновляем статистику при открытии и каждую секунду
        LaunchedEffect(showDataStorage, isClearing) {
            if (showDataStorage && !isClearing) {
                while (true) {
                    cacheStats = cacheManager.getCacheStats()
                    kotlinx.coroutines.delay(1000)
                }
            }
        }
        
        Dialog(
            onDismissRequest = { showDataStorage = false },
            properties = androidx.compose.ui.window.DialogProperties(
                usePlatformDefaultWidth = false
            )
        ) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                DataStorageScreen(
                    cacheStats = cacheStats,
                    avatarCacheSize = cacheManager.getAvatarCacheSize(),
                    avatarCount = cacheManager.getAvatarCount(),
                    onClearCache = {
                        scope.launch {
                            isClearing = true
                            try {
                                cacheManager.clearAllCache()
                                kotlinx.coroutines.delay(300)
                                cacheStats = cacheManager.getCacheStats()
                                chatViewModel.loadChats(identity.id)
                            } catch (e: Exception) {
                                Log.e("MainActivity", "Error clearing cache", e)
                            } finally {
                                isClearing = false
                            }
                        }
                    },
                    onClearAvatarCache = {
                        scope.launch {
                            try {
                                cacheManager.clearAvatarCache()
                                kotlinx.coroutines.delay(300)
                                cacheStats = cacheManager.getCacheStats()
                            } catch (e: Exception) {
                                Log.e("MainActivity", "Error clearing avatar cache", e)
                            }
                        }
                    },
                    onDismiss = { showDataStorage = false }
                )
            }
        }
    }
    
    // Privacy Settings Dialog
    if (showPrivacySettings) {
        Dialog(
            onDismissRequest = { showPrivacySettings = false },
            properties = androidx.compose.ui.window.DialogProperties(
                usePlatformDefaultWidth = false
            )
        ) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                PrivacySettingsScreen(
                    identityId = identity.id,
                    repository = com.bananjemmy.data.repository.JemmyRepository(),
                    onBack = { showPrivacySettings = false },
                    onNavigateToBlockedUsers = {
                        showPrivacySettings = false
                        showBlockedUsers = true
                    }
                )
            }
        }
    }
    
    // Blocked Users Dialog
    if (showBlockedUsers) {
        Dialog(
            onDismissRequest = { showBlockedUsers = false },
            properties = androidx.compose.ui.window.DialogProperties(
                usePlatformDefaultWidth = false
            )
        ) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                BlockedUsersScreen(
                    currentUserId = identity.id,
                    onBack = { showBlockedUsers = false },
                    cacheManager = cacheManager
                )
            }
        }
    }
    
    // Invite Profile Dialog
    pendingInvite?.let { (inviteIdentity, token) ->
        Dialog(
            onDismissRequest = { chatViewModel.setPendingInvite(null, null) },
            properties = androidx.compose.ui.window.DialogProperties(
                usePlatformDefaultWidth = false
            )
        ) {
            InviteProfileScreen(
                identity = inviteIdentity,
                token = token,
                onStartChat = { inviteToken, myId ->
                    val repository = com.bananjemmy.data.repository.JemmyRepository()
                    repository.startChatByInvite(inviteToken, myId).map { it.chatId }
                },
                myIdentityId = identity.id,
                onDismiss = { chatViewModel.setPendingInvite(null, null) },
                onChatCreated = { chatId ->
                    Log.d("MainActivity", "Chat created from invite: $chatId")
                    chatViewModel.loadChats(identity.id)
                    chatViewModel.setPendingInvite(null, null)
                    selectedTab = 0
                }
            )
        }
    }
}
