# Установка AndroidLibXrayLite

## Правильная библиотека от 2dust (автор v2rayNG)

Это официальная библиотека Xray для Android от создателя v2rayNG.

## Установка

### Шаг 1: Скачать библиотеку

Скачай последний релиз:
https://github.com/2dust/AndroidLibXrayLite/releases

Файлы:
- `libv2ray.aar` - основная библиотека
- `libv2ray-sources.jar` - исходники (опционально)

### Шаг 2: Создать папку libs

```bash
mkdir -p app/libs
```

### Шаг 3: Положить AAR в libs

Скопируй `libv2ray.aar` в `app/libs/`

### Шаг 4: Добавить в app/build.gradle.kts

```kotlin
dependencies {
    // ... другие зависимости
    
    // AndroidLibXrayLite
    implementation(files("libs/libv2ray.aar"))
    
    // Зависимости для работы библиотеки
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```

### Шаг 5: Настроить AndroidManifest.xml

Убедись что есть:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<application
    android:extractNativeLibs="true"
    ...>
```

### Шаг 6: Использование

```kotlin
import libv2ray.Libv2ray
import libv2ray.V2RayPoint
import libv2ray.V2RayVPNServiceSupportsSet

// В VPN Service
class MyVpnService : VpnService(), V2RayVPNServiceSupportsSet {
    
    private val v2rayPoint: V2RayPoint = Libv2ray.newV2RayPoint(this, true)
    
    fun startVpn(config: String) {
        v2rayPoint.configureFileContent = config
        v2rayPoint.runLoop(true)
    }
    
    fun stopVpn() {
        v2rayPoint.stopLoop()
    }
    
    // Реализация интерфейса V2RayVPNServiceSupportsSet
    override fun onEmitStatus(status: String?): Long {
        Log.d("V2Ray", "Status: $status")
        return 0
    }
    
    override fun protect(fd: Long): Boolean {
        return protect(fd.toInt())
    }
    
    override fun setup(config: String?): Long {
        val builder = Builder()
            .setSession("My VPN")
            .setMtu(1500)
            .addAddress("26.26.26.1", 30)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("8.8.8.8")
        
        val vpnInterface = builder.establish()
        return vpnInterface?.fd?.toLong() ?: 0
    }
}
```

## Формат конфига

Библиотека принимает JSON конфиг V2Ray/Xray:

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": 10808,
    "protocol": "socks",
    "settings": {
      "auth": "noauth",
      "udp": true
    }
  }],
  "outbounds": [{
    "protocol": "vless",
    "settings": {
      "vnext": [{
        "address": "server.com",
        "port": 443,
        "users": [{
          "id": "uuid-here",
          "encryption": "none"
        }]
      }]
    },
    "streamSettings": {
      "network": "ws",
      "security": "tls",
      "tlsSettings": {
        "serverName": "server.com"
      },
      "wsSettings": {
        "path": "/path"
      }
    }
  }]
}
```

## Конвертация VLESS URL в JSON

Нужно парсить VLESS URL и конвертировать в JSON конфиг.

Пример парсера уже есть в `JemmyVpnService.kt` (функция `convertVlessToConfig`)

## Проверка работы

```kotlin
// Получить версию
val version = Libv2ray.checkVersionX()
Log.d("V2Ray", "Version: $version")
```

## Troubleshooting

### Ошибка: "Native library not found"

1. Проверь что `android:extractNativeLibs="true"` в манифесте
2. Проверь что AAR файл в `app/libs/`
3. Очисти проект: `./gradlew clean`

### Ошибка: "Class not found"

1. Проверь что зависимость добавлена в build.gradle
2. Синхронизируй проект: File -> Sync Project with Gradle Files

### VPN не подключается

1. Проверь что реализованы все методы интерфейса `V2RayVPNServiceSupportsSet`
2. Проверь что VPN разрешение получено
3. Проверь логи: `adb logcat | grep V2Ray`

## Ссылки

- GitHub: https://github.com/2dust/AndroidLibXrayLite
- v2rayNG (пример использования): https://github.com/2dust/v2rayNG
- Xray документация: https://xtls.github.io/
