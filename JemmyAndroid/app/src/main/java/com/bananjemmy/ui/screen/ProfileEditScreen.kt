package com.bananjemmy.ui.screen

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.Identity
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileEditScreen(
    identity: Identity,
    onCheckUsername: suspend (String) -> Result<Boolean>,
    onSave: suspend (String, String, String?) -> Result<Identity>,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    var username by remember { mutableStateOf(identity.username) }
    var bio by remember { mutableStateOf(identity.bio) }
    var avatarBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var avatarBase64 by remember { mutableStateOf<String?>(null) }
    var isCheckingUsername by remember { mutableStateOf(false) }
    var usernameAvailable by remember { mutableStateOf<Boolean?>(null) }
    var isSaving by remember { mutableStateOf(false) }
    var showError by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    var checkUsernameJob by remember { mutableStateOf<Job?>(null) }
    
    val coroutineScope = rememberCoroutineScope()
    
    // Image picker launcher
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            try {
                val inputStream = context.contentResolver.openInputStream(it)
                val bitmap = BitmapFactory.decodeStream(inputStream)
                inputStream?.close()
                
                // Resize if too large
                val maxSize = 512
                val ratio = maxSize.toFloat() / maxOf(bitmap.width, bitmap.height)
                val resizedBitmap = if (ratio < 1) {
                    Bitmap.createScaledBitmap(
                        bitmap,
                        (bitmap.width * ratio).toInt(),
                        (bitmap.height * ratio).toInt(),
                        true
                    )
                } else {
                    bitmap
                }
                
                avatarBitmap = resizedBitmap
                
                // Convert to base64
                val outputStream = ByteArrayOutputStream()
                resizedBitmap.compress(Bitmap.CompressFormat.JPEG, 80, outputStream)
                val bytes = outputStream.toByteArray()
                avatarBase64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
                
            } catch (e: Exception) {
                errorMessage = "Не удалось загрузить изображение"
                showError = true
            }
        }
    }
    
    // Username validation
    fun isValidUsername(username: String): Boolean {
        return username.matches(Regex("^[a-zA-Z0-9_]{4,16}$"))
    }
    
    // Check username with debounce
    fun checkUsernameDebounced() {
        checkUsernameJob?.cancel()
        
        if (username == identity.username) {
            usernameAvailable = true
            return
        }
        
        if (!isValidUsername(username)) {
            usernameAvailable = false
            return
        }
        
        checkUsernameJob = coroutineScope.launch {
            delay(500) // Debounce 0.5 seconds
            isCheckingUsername = true
            val result = onCheckUsername(username)
            result.onSuccess { available ->
                usernameAvailable = available
            }.onFailure {
                usernameAvailable = false
            }
            isCheckingUsername = false
        }
    }
    
    val isValid = isValidUsername(username) && (usernameAvailable == true || username == identity.username)
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Редактировать") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Filled.Close, contentDescription = "Отмена")
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            isSaving = true
                            coroutineScope.launch {
                                val result = onSave(username, bio, avatarBase64)
                                result.onSuccess {
                                    onDismiss()
                                }.onFailure {
                                    errorMessage = "Не удалось сохранить. Возможно, username уже занят."
                                    showError = true
                                }
                                isSaving = false
                            }
                        },
                        enabled = isValid && !isSaving
                    ) {
                        if (isSaving) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text(
                                "Готово",
                                fontWeight = FontWeight.SemiBold,
                                color = if (isValid) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                            )
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(24.dp))
            
            // Avatar with click to change
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer)
                    .clickable { imagePickerLauncher.launch("image/*") },
                contentAlignment = Alignment.Center
            ) {
                if (avatarBitmap != null) {
                    androidx.compose.foundation.Image(
                        bitmap = avatarBitmap!!.asImageBitmap(),
                        contentDescription = "Avatar",
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    Text(
                        text = username.take(2).uppercase(),
                        fontSize = 40.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
                
                // Camera icon overlay
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.3f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Filled.Edit,
                        contentDescription = "Изменить фото",
                        tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        modifier = Modifier.size(32.dp)
                    )
                }
            }
            
            Text(
                text = "Нажмите, чтобы изменить фото",
                fontSize = 13.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                modifier = Modifier.padding(top = 8.dp)
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // Username field
            OutlinedTextField(
                value = username,
                onValueChange = {
                    username = it
                    usernameAvailable = null
                    checkUsernameDebounced()
                },
                label = { Text("Username") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                trailingIcon = {
                    when {
                        isCheckingUsername -> CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp
                        )
                        usernameAvailable == true -> Icon(
                            Icons.Filled.CheckCircle,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                        usernameAvailable == false -> Icon(
                            Icons.Filled.Close,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                },
                supportingText = {
                    when {
                        !isValidUsername(username) && username.isNotEmpty() -> 
                            Text("4-16 символов: a-z, 0-9, _", color = MaterialTheme.colorScheme.error)
                        usernameAvailable == false && username != identity.username -> 
                            Text("Username уже занят", color = MaterialTheme.colorScheme.error)
                    }
                },
                isError = (!isValidUsername(username) && username.isNotEmpty()) || 
                         (usernameAvailable == false && username != identity.username)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Bio field
            OutlinedTextField(
                value = bio,
                onValueChange = { bio = it },
                label = { Text("О себе") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                maxLines = 4
            )
            
            Spacer(modifier = Modifier.height(16.dp))
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
