# Devices Management Feature

## Реализовано:

### 1. Android
- ✅ Модель Device (Device.kt)
- ✅ DevicesScreen с Material Design 3
- ✅ Цветовая кодировка платформ (iOS - синий, Android - зеленый, macOS - фиолетовый)
- ✅ Отображение информации об устройстве (модель, ОС, версия приложения)
- ✅ Функция выхода с устройства
- ✅ Метка "Текущее" для активного устройства

### 2. Необходимо добавить в JemmyApiService.kt:
```kotlin
// Device endpoints
@GET("api/devices/{identityId}")
suspend fun getDevices(@Path("identityId") identityId: String): Response<DevicesResponse>

@POST("api/devices/register")
suspend fun registerDevice(@Body request: RegisterDeviceRequest): Response<Device>

@POST("api/devices/logout")
suspend fun logoutDevice(@Body request: LogoutDeviceRequest): Response<Unit>

@PUT("api/devices/{deviceId}/activity")
suspend fun updateDeviceActivity(@Path("deviceId") deviceId: String): Response<Unit>
```

### 3. Необходимо добавить в JemmyRepository.kt:
```kotlin
suspend fun getDevices(identityId: String): Result<DevicesResponse> {
    return try {
        val response = apiService.getDevices(identityId)
        if (response.isSuccessful && response.body() != null) {
            Result.success(response.body()!!)
        } else {
            Result.failure(Exception("Failed to load devices"))
        }
    } catch (e: Exception) {
        Result.failure(e)
    }
}

suspend fun registerDevice(
    identityId: String,
    deviceName: String,
    deviceModel: String,
    platform: String,
    osVersion: String,
    appVersion: String
): Result<Device> {
    return try {
        val request = RegisterDeviceRequest(
            identityId, deviceName, deviceModel, platform, osVersion, appVersion
        )
        val response = apiService.registerDevice(request)
        if (response.isSuccessful && response.body() != null) {
            Result.success(response.body()!!)
        } else {
            Result.failure(Exception("Failed to register device"))
        }
    } catch (e: Exception) {
        Result.failure(e)
    }
}

suspend fun logoutDevice(identityId: String, deviceId: String): Result<Unit> {
    return try {
        val request = LogoutDeviceRequest(identityId, deviceId)
        val response = apiService.logoutDevice(request)
        if (response.isSuccessful) {
            Result.success(Unit)
        } else {
            Result.failure(Exception("Failed to logout device"))
        }
    } catch (e: Exception) {
        Result.failure(e)
    }
}
```

### 4. Добавить в ProfileScreen.kt навигацию:
```kotlin
onNavigateToDevices: () -> Unit = {}

// В списке настроек:
ListItem(
    headlineContent = { Text("Устройства") },
    supportingContent = { Text("Управление активными сеансами") },
    leadingContent = {
        Icon(Icons.Filled.Devices, contentDescription = null)
    },
    trailingContent = {
        Icon(Icons.Filled.KeyboardArrowRight, contentDescription = null)
    },
    modifier = Modifier.clickable { onNavigateToDevices() }
)
```

### 5. Добавить в MainActivity.kt:
```kotlin
var showDevices by remember { mutableStateOf(false) }

// В ProfileScreen:
onNavigateToDevices = { showDevices = true }

// Dialog для Devices:
if (showDevices) {
    Dialog(
        onDismissRequest = { showDevices = false },
        properties = androidx.compose.ui.window.DialogProperties(
            usePlatformDefaultWidth = false
        )
    ) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            DevicesScreen(
                identityId = identity.id,
                onBack = { showDevices = false }
            )
        }
    }
}
```

### 6. Server.js - добавить схему и endpoints:
```javascript
// Device Schema
const deviceSchema = new mongoose.Schema({
  identity_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Identity', required: true },
  device_id: { type: String, required: true, unique: true },
  device_name: { type: String, required: true },
  device_model: { type: String, required: true },
  platform: { type: String, required: true }, // 'android', 'ios', 'macos'
  os_version: { type: String, required: true },
  app_version: { type: String, required: true },
  last_active: { type: Date, default: Date.now }
}, { timestamps: true });

const Device = mongoose.model('Device', deviceSchema);

// API Endpoints
app.get('/api/devices/:identityId', async (req, res) => {
  try {
    const devices = await Device.find({ identity_id: req.params.identityId })
      .sort({ last_active: -1 });
    
    const currentDeviceId = req.headers['x-device-id'];
    const devicesWithCurrent = devices.map(d => ({
      id: d._id,
      identityId: d.identity_id,
      deviceName: d.device_name,
      deviceModel: d.device_model,
      platform: d.platform,
      osVersion: d.os_version,
      appVersion: d.app_version,
      lastActive: d.last_active.getTime(),
      isCurrent: d.device_id === currentDeviceId
    }));
    
    res.json({ devices: devicesWithCurrent });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/devices/register', async (req, res) => {
  try {
    const { identityId, deviceName, deviceModel, platform, osVersion, appVersion } = req.body;
    const deviceId = req.headers['x-device-id'];
    
    let device = await Device.findOne({ device_id: deviceId });
    
    if (device) {
      device.identity_id = identityId;
      device.device_name = deviceName;
      device.device_model = deviceModel;
      device.platform = platform;
      device.os_version = osVersion;
      device.app_version = appVersion;
      device.last_active = new Date();
      await device.save();
    } else {
      device = new Device({
        identity_id: identityId,
        device_id: deviceId,
        device_name: deviceName,
        device_model: deviceModel,
        platform: platform,
        os_version: osVersion,
        app_version: appVersion
      });
      await device.save();
    }
    
    res.json(device);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/devices/logout', async (req, res) => {
  try {
    const { deviceId } = req.body;
    await Device.findByIdAndDelete(deviceId);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### 7. iOS - аналогичная реализация (DevicesView.swift)

## Следующие шаги:
1. Добавить API endpoints в JemmyApiService
2. Добавить методы в JemmyRepository
3. Обновить ProfileScreen с навигацией
4. Добавить dialog в MainActivity
5. Обновить server.js с device schema и endpoints
6. Создать DevicesView для iOS
7. Добавить локальное кэширование устройств
8. Регистрировать устройство при входе
9. Обновлять last_active при активности
