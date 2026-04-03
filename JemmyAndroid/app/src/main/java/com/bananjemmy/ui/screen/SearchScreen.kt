package com.bananjemmy.ui.screen

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.Identity
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    onSearch: suspend (String) -> Result<List<Identity>>,
    onStartChat: suspend (Identity) -> Result<String>,
    onDismiss: () -> Unit,
    onChatCreated: (String) -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }
    var foundIdentities by remember { mutableStateOf<List<Identity>>(emptyList()) }
    var isSearching by remember { mutableStateOf(false) }
    var isCreatingChat by remember { mutableStateOf(false) }
    var showError by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Найти пользователя") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = "Закрыть")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            // Search field
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Введи username") },
                leadingIcon = {
                    Icon(Icons.Filled.Search, contentDescription = null)
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Filled.Clear, contentDescription = "Очистить")
                        }
                    }
                },
                singleLine = true
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Search button
            val coroutineScope = rememberCoroutineScope()
            Button(
                onClick = {
                    isSearching = true
                    coroutineScope.launch {
                        val result = onSearch(searchQuery)
                        result.onSuccess { identities ->
                            foundIdentities = identities
                            if (identities.isEmpty()) {
                                errorMessage = "Пользователь $searchQuery не найден"
                                showError = true
                            }
                        }.onFailure {
                            errorMessage = "Пользователь $searchQuery не найден"
                            showError = true
                            foundIdentities = emptyList()
                        }
                        isSearching = false
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = searchQuery.isNotEmpty() && !isSearching
            ) {
                if (isSearching) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Text("Найти")
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // Found users
            foundIdentities.forEach { identity ->
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Avatar
                        Surface(
                            modifier = Modifier.size(80.dp),
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.primaryContainer
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    text = identity.username.take(2).uppercase(),
                                    fontSize = 32.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = identity.username,
                            fontSize = 22.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        
                        if (identity.bio.isNotEmpty()) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = identity.bio,
                                fontSize = 15.sp,
                                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                                textAlign = TextAlign.Center
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(24.dp))
                        
                        val chatCoroutineScope = rememberCoroutineScope()
                        Button(
                            onClick = {
                                isCreatingChat = true
                                chatCoroutineScope.launch {
                                    val result = onStartChat(identity)
                                    result.onSuccess { chatId ->
                                        onChatCreated(chatId)
                                        onDismiss()
                                    }.onFailure {
                                        errorMessage = "Не удалось создать чат"
                                        showError = true
                                    }
                                    isCreatingChat = false
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = !isCreatingChat
                        ) {
                            if (isCreatingChat) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(20.dp),
                                    strokeWidth = 2.dp,
                                    color = MaterialTheme.colorScheme.onPrimary
                                )
                            } else {
                                Text("Начать чат")
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
            }
        }
    }
    
    if (showError) {
        AlertDialog(
            onDismissRequest = { showError = false },
            title = { Text("Ошибка") },
            text = { Text(errorMessage) },
            confirmButton = {
                TextButton(onClick = { showError = false }) {
                    Text("OK")
                }
            }
        )
    }
}
