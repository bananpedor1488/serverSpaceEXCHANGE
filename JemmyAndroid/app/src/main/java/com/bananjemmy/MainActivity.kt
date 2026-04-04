package com.bananjemmy

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import com.bananjemmy.data.model.Chat
import com.bananjemmy.data.model.Identity
import com.bananjemmy.data.repository.JemmyRepository
import com.bananjemmy.ui.screen.ChatListScreen
import com.bananjemmy.ui.screen.ChatScreen
import com.bananjemmy.ui.screen.DataStorageScreen
import com.bananjemmy.ui.screen.InviteProfileScreen
import com.bananjemmy.ui.screen.LinkGeneratorScreen
import com.bananjemmy.ui.screen.OnboardingScreen
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
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("MainActivity", "🚀 onCreate started")
        
        // Initialize cache manager
        cacheManager = com.bananjemmy.data.cache.CacheManager(this)
        Log.d("MainActivity", "✅ CacheManager created: $cacheManager")
        
        chatViewModel = ChatViewModel(cacheManager)
        Log.d("MainActivity", "✅ ChatViewModel created with CacheManager")
        
        // Check auth on start
        authViewModel.checkAuth(this)
        
        // Handle deep link
        handleDeepLink(intent)
        
        enableEdgeToEdge()
        setContent {
            JemmyTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    JemmyApp(
                        authViewModel = authViewModel,
                        chatViewModel = chatViewModel,
                        cacheManager = cacheManager
                    )
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d("MainActivity", "🔌 onDestroy - disconnecting WebSocket")
        chatViewModel.disconnectWebSocket()
    }
    
    private fun handleDeepLink(intent: Intent?) {
        val data: Uri? = intent?.data
        data?.let { uri ->
            Log.d("MainActivity", "🔗 Deep link received: $uri")
            Log.d("MainActivity", "🔗 Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}")
            
            val token = when {
                // jemmy://invite/{token}
                uri.scheme == "jemmy" && uri.host == "invite" -> {
                    uri.lastPathSegment
                }
                // https://weeky-six.vercel.app/api/u/{token}
                uri.scheme == "https" && uri.pathSegments.contains("u") -> {
                    uri.lastPathSegment
                }
                else -> null
            }
            
            if (token != null) {
                Log.d("MainActivity", "✅ Loading invite preview for token: $token")
                // Load invite preview
                val repository = JemmyRepository()
                lifecycleScope.launch {
                    val result = repository.previewInviteLink(token)
                    result.onSuccess { identity ->
                        Log.d("MainActivity", "✅ Invite preview loaded: ${identity.username}")
                        chatViewModel.setPendingInvite(identity, token)
                    }.onFailure {
                        Log.e("MainActivity", "❌ Failed to load invite preview: ${it.message}")
                    }
                }
            } else {
                Log.d("MainActivity", "⚠️ Could not extract token from URI")
            }
        }
    }
}

@Composable
fun JemmyApp(
    authViewModel: AuthViewModel,
    chatViewModel: ChatViewModel,
    cacheManager: com.bananjemmy.data.cache.CacheManager
) {
    val authState by authViewModel.authState.collectAsStateWithLifecycle()
    val pendingInvite by chatViewModel.pendingInvite.collectAsStateWithLifecycle()
    
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
        
        is AuthState.Authenticated -> {
            val identity = state.identity
            
            // Load chats when authenticated
            LaunchedEffect(identity.id) {
                Log.d("MainActivity", "📡 Loading chats for identity: ${identity.id}")
                chatViewModel.loadChats(identity.id)
                chatViewModel.connectWebSocket(identity.id, identity.id)
            }
            
            DisposableEffect(Unit) {
                onDispose {
                    chatViewModel.disconnectWebSocket()
                }
            }
            
            MainScreen(
                identity = identity,
                chatViewModel = chatViewModel,
                authViewModel = authViewModel,
                cacheManager = cacheManager,
                showInviteProfile = pendingInvite,
                onShowInviteProfile = { chatViewModel.setPendingInvite(it?.first, it?.second) }
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
    cacheManager: com.bananjemmy.data.cache.CacheManager,
    showInviteProfile: Pair<Identity, String>?,
    onShowInviteProfile: (Pair<Identity, String>?) -> Unit
) {
    var selectedTab by remember { mutableIntStateOf(0) }
    var showLinkGenerator by remember { mutableStateOf(false) }
    var showSearch by remember { mutableStateOf(false) }
    var showEditProfile by remember { mutableStateOf(false) }
    var showDataStorage by remember { mutableStateOf(false) }
    var selectedChat by remember { mutableStateOf<Chat?>(null) }
    
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
                    repository.searchByUsername(username)
                },
                onStartChat = { foundIdentity ->
                    val repository = com.bananjemmy.data.repository.JemmyRepository()
                    val result = repository.startDirectChat(identity.id, foundIdentity.id)
                    result.map { it.chatId }
                },
                onDismiss = { showSearch = false },
                onChatCreated = { chatId ->
                    Log.d("MainActivity", "Chat created: $chatId")
                    chatViewModel.loadChats(identity.id)
                    showSearch = false
                    selectedTab = 0
                }
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
                        lastSeen = chat.lastSeen ?: 0L
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
                                
                                // Polling для списка чатов каждые 0.5 секунды
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
                                    cacheManager = cacheManager
                                )
                            }
                            1 -> {
                                ProfileScreen(
                                    identity = identity,
                                    authViewModel = authViewModel,
                                    onNavigateToLinkGenerator = { showLinkGenerator = true },
                                    onNavigateToSearch = { showSearch = true },
                                    onNavigateToEdit = { showEditProfile = true },
                                    onNavigateToDataStorage = { showDataStorage = true }
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
                                    cacheManager.saveAvatar(identity.id, avatar, updatedIdentity.avatarUpdatedAt)
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
    
    // Invite Profile Dialog
    showInviteProfile?.let { (inviteIdentity, token) ->
        Dialog(
            onDismissRequest = { onShowInviteProfile(null) },
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
                onDismiss = { onShowInviteProfile(null) },
                onChatCreated = { chatId ->
                    Log.d("MainActivity", "Chat created from invite: $chatId")
                    chatViewModel.loadChats(identity.id)
                    onShowInviteProfile(null)
                    selectedTab = 0
                }
            )
        }
    }
}
