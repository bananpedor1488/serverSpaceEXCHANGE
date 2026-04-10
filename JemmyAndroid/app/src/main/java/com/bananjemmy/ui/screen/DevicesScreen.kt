package com.bananjemmy.ui.screen

import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bananjemmy.data.model.Device
import com.bananjemmy.data.repository.JemmyRepository
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DevicesScreen(
    identityId: String,
    onBack: () -> Unit
) {
    val repository = remember { JemmyRepository() }
    val coroutineScope = rememberCoroutineScope()
    val context = androidx.compose.ui.platform.LocalContext.current
    
    var devices by remember { mutableStateOf<List<Device>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var showLogoutDialog by remember { mutableStateOf<Device?>(null) }
    
    // Get app version
    val packageInfo = remember {
        context.packageManager.getPackageInfo(context.packageName, 0)
    }
    val appVersion = packageInfo.versionName
    
    // Load devices
    LaunchedEffect(identityId) {
        isLoading = true
        val result = repository.getDevices(identityId)
        result.onSuccess { devicesResponse ->
            devices = devicesResponse.devices
        }
        isLoading = false
    }
    
    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Устройства") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, "Назад")
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
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
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Info card
                item {
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 8.dp),
                        shape = RoundedCornerShape(12.dp),
                        color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Info,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(20.dp)
                            )
                            Text(
                                text = "Список всех устройств, на которых выполнен вход в ваш аккаунт",
                                fontSize = 13.sp,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                                lineHeight = 18.sp
                            )
                        }
                    }
                }
                
                // Devices list
                items(devices) { device ->
                    DeviceItem(
                        device = device,
                        onLogout = { showLogoutDialog = device }
                    )
                }
                
                if (devices.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "Нет активных устройств",
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Logout confirmation dialog
    showLogoutDialog?.let { device ->
        AlertDialog(
            onDismissRequest = { showLogoutDialog = null },
            icon = {
                Icon(
                    imageVector = Icons.Filled.Warning,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error
                )
            },
            title = { Text("Завершить сеанс?") },
            text = {
                Text("Вы уверены, что хотите выйти из аккаунта на устройстве \"${device.deviceName}\"?")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        coroutineScope.launch {
                            val result = repository.logoutDevice(identityId, device.id)
                            result.onSuccess {
                                devices = devices.filter { it.id != device.id }
                            }
                            showLogoutDialog = null
                        }
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Завершить")
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = null }) {
                    Text("Отмена")
                }
            }
        )
    }
}

@Composable
fun DeviceItem(
    device: Device,
    onLogout: () -> Unit
) {
    val platformColor = when (device.platform.lowercase()) {
        "ios" -> Color(0xFF007AFF)
        "android" -> Color(0xFF3DDC84)
        "macos" -> Color(0xFF5856D6)
        else -> MaterialTheme.colorScheme.primary
    }
    
    val platformIcon = Icons.Filled.Phone
    
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.weight(1f)
                ) {
                    // Platform icon with color
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .background(platformColor.copy(alpha = 0.1f), RoundedCornerShape(10.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = platformIcon,
                            contentDescription = null,
                            tint = platformColor,
                            modifier = Modifier.size(22.dp)
                        )
                    }
                    
                    Column {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = device.deviceName,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurface,
                                maxLines = 1,
                                modifier = Modifier.weight(1f, fill = false)
                            )
                            if (device.isCurrent) {
                                Surface(
                                    shape = RoundedCornerShape(4.dp),
                                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                                ) {
                                    Text(
                                        text = "Текущее",
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp)
                                    )
                                }
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(2.dp))
                        
                        Text(
                            text = device.deviceModel,
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                            maxLines = 1
                        )
                    }
                }
                
                if (!device.isCurrent) {
                    IconButton(onClick = onLogout) {
                        Icon(
                            imageVector = Icons.Filled.Close,
                            contentDescription = "Завершить сеанс",
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Divider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Device info
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Платформа",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                    Text(
                        text = "${device.platform.uppercase()} ${device.osVersion}",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
                
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "Версия приложения",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                    Text(
                        text = device.appVersion,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(6.dp))
            
            Text(
                text = "Последняя активность: ${formatLastActive(device.lastActive)}",
                fontSize = 11.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
            )
        }
    }
}

private fun formatLastActive(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp
    
    return when {
        diff < 60_000 -> "только что"
        diff < 3600_000 -> "${diff / 60_000} мин назад"
        diff < 86400_000 -> "${diff / 3600_000} ч назад"
        diff < 604800_000 -> "${diff / 86400_000} дн назад"
        else -> {
            val sdf = SimpleDateFormat("dd.MM.yyyy", Locale.getDefault())
            sdf.format(Date(timestamp))
        }
    }
}

// Helper function to get current device info
fun getCurrentDeviceInfo(): Triple<String, String, String> {
    val deviceName = "${Build.MANUFACTURER} ${Build.MODEL}"
    val deviceModel = Build.MODEL
    val osVersion = Build.VERSION.RELEASE
    return Triple(deviceName, deviceModel, osVersion)
}
