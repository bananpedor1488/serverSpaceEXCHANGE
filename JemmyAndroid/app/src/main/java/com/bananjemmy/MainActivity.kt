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
import com.bananjemmy.data.model.Chat
import com.bananjemmy.data.model.Identity
import com.bananjemmy.ui.screen.ChatListScreen
import com.bananjemmy.ui.screen.ChatScreen
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
    private val chatViewModel: ChatViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("MainActivity", "onCreate")
        
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
                        chatViewModel = chatViewModel
                    )
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }
    
    private fun handleDeepLink(intent: Intent?) {
        val data: Uri? = intent?.data
        data?.let { uri ->
            Log.d("MainActivity", "Deep link received: $uri")
            
            // Extract token from URL: https://weeky-six.vercel.app/api/u/{token}
            val token = uri.lastPathSegment
            if (token != null && uri.pathSegments.contains("u")) {
                Log.d("MainActivity", "Starting chat by token: $token")
                chatViewModel.startChatByToken(token) { chat ->
                    Log.d("MainActivity", "Chat started: ${chat.id}")
                    // Navigate to chat screen
                }
            }
        }
    }
}

@Composable
fun JemmyApp(
    authViewModel: AuthViewModel,
    chatViewModel: ChatViewModel
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
                authViewModel = authViewModel
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
    authViewModel: AuthViewModel
) {
    var selectedTab by remember { mutableIntStateOf(0) }
    var showLinkGenerator by remember { mutableStateOf(false) }
    var showSearch by remember { mutableStateOf(false) }
    var showEditProfile by remember { mutableStateOf(false) }
    var selectedChat by remember { mutableStateOf<Chat?>(null) }
    
    Scaffold(
        bottomBar = {
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
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            if (selectedChat != null) {
                ChatScreen(
                    chatId = selectedChat!!.id,
                    otherUser = selectedChat!!.user,
                    currentUserId = identity.id,
                    chatViewModel = chatViewModel,
                    onBack = { selectedChat = null }
                )
            } else {
                when (selectedTab) {
                0 -> {
                    val chatListState by chatViewModel.chatListState.collectAsStateWithLifecycle()
                    ChatListScreen(
                        chatListState = chatListState,
                        currentUserId = identity.id,
                        onChatClick = { chat ->
                            selectedChat = chat
                        },
                        onRefresh = {
                            chatViewModel.loadChats(identity.id)
                        }
                    )
                }
                1 -> {
                    ProfileScreen(
                        identity = identity,
                        authViewModel = authViewModel,
                        onNavigateToLinkGenerator = { showLinkGenerator = true },
                        onNavigateToSearch = { showSearch = true },
                        onNavigateToEdit = { showEditProfile = true }
                    )
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
    
    // Search Dialog
    if (showSearch) {
        Dialog(onDismissRequest = { showSearch = false }) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
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
                        selectedTab = 0
                    }
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
                        val repository = com.bananjemmy.data.repository.JemmyRepository()
                        repository.checkUsername(username)
                    },
                    onSave = { username, bio ->
                        val repository = com.bananjemmy.data.repository.JemmyRepository()
                        val result = repository.updateProfile(identity.id, username, bio)
                        result.onSuccess { updatedIdentity ->
                            authViewModel.updateLocalIdentity(updatedIdentity)
                        }
                        result
                    },
                    onDismiss = { showEditProfile = false }
                )
            }
        }
    }
}
