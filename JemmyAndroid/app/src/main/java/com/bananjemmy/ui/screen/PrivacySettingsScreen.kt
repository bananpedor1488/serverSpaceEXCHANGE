package com.bananjemmy.ui.screen

import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.PrivacySettings
import com.bananjemmy.data.model.UpdatePrivacySettingsRequest
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrivacySettingsScreen(
    identityId: String,
    repository: com.bananjemmy.data.repository.JemmyRepository,
    onBack: () -> Unit
) {
    var privacySettings by remember { mutableStateOf<PrivacySettings?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var isSaving by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()
    val scrollState = rememberScrollState()
    
    // Load settings
    LaunchedEffect(identityId) {
        isLoading = true
        try {
            val result = repository.getPrivacySettings(identityId)
            result.fold(
                onSuccess = { settings ->
                    privacySettings = settings
                    Log.d("PrivacySettings", "✅ Loaded settings: $settings")
                },
                onFailure = { error ->
                    Log.e("PrivacySettings", "❌ Failed to load: ${error.message}")
                }
            )
        } catch (e: Exception) {
            Log.e("PrivacySettings", "❌ Error: ${e.message}")
        } finally {
            isLoading = false
        }
    }
    
    fun saveSettings(newSettings: PrivacySettings) {
        coroutineScope.launch {
            isSaving = true
            try {
                val request = UpdatePrivacySettingsRequest(
                    identityId = identityId,
                    settings = newSettings
                )
                val result = repository.updatePrivacySettings(request)
                result.fold(
                    onSuccess = { response ->
                        privacySettings = response.privacySettings
                        Log.d("PrivacySettings", "✅ Settings saved")
                    },
                    onFailure = { error ->
                        Log.e("PrivacySettings", "❌ Failed to save: ${error.message}")
                    }
                )
            } catch (e: Exception) {
                Log.e("PrivacySettings", "❌ Error saving: ${e.message}")
            } finally {
                isSaving = false
            }
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Приватность") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Назад")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { paddingValues ->
        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (privacySettings != null) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .verticalScroll(scrollState)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Защита от скриншотов
                PrivacySection(title = "Безопасность") {
                    SettingsToggleItem(
                        icon = "🔒",
                        title = "Защита от скриншотов",
                        description = "Собеседники увидят уведомление",
                        checked = privacySettings!!.screenshotProtection,
                        enabled = !isSaving,
                        onCheckedChange = { checked ->
                            val newSettings = privacySettings!!.copy(screenshotProtection = checked)
                            privacySettings = newSettings
                            saveSettings(newSettings)
                        }
                    )
                }
            }
        } else {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Не удалось загрузить настройки",
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}

@Composable
fun PrivacySection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = title,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
            modifier = Modifier.padding(horizontal = 4.dp)
        )
        
        Column(
            verticalArrangement = Arrangement.spacedBy(8.dp),
            content = content
        )
    }
}

@Composable
fun SettingsToggleItem(
    icon: String,
    title: String,
    description: String,
    checked: Boolean,
    enabled: Boolean = true,
    onCheckedChange: (Boolean) -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = Color.White.copy(alpha = 0.05f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = icon,
                    fontSize = 24.sp
                )
                
                Column(
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = title,
                        fontSize = 17.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    
                    Text(
                        text = description,
                        fontSize = 13.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                }
            }
            
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange,
                enabled = enabled,
                colors = SwitchDefaults.colors(
                    checkedThumbColor = Color.White,
                    checkedTrackColor = Color(0xFF34C759)
                )
            )
        }
    }
}
