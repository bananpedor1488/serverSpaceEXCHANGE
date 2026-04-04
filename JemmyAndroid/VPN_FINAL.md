# Jemmy VPN - Рабочая реализация на V2ray-Android

## Что сделано

Интегрирована готовая рабочая библиотека [V2ray-Android](https://github.com/dev7dev/V2ray-Android) с поддержкой VLESS, VMESS, Shadowsocks, Trojan и других протоколов.

### Компоненты:

1. **V2rayManager.kt** - Обертка над V2rayController
   - Инициализация V2ray core
   - Управление подключением
   - Получение статуса
   - Получение версии ядра

2. **VpnPinger.kt** - Проверка доступности серверов
   - TCP пинг хоста и порта
   - Измерение задержки
   - Множественные пинги

3. **VpnConfigManager.kt** - Управление конфигурациями
   - Сохранение/удаление конфигов
   - Выбор активного конфига
   - Сохранение результатов пинга

4. **UI экраны:**
   - VpnScreen - список конфигов, подключение
   - AddVpnConfigScreen - добавление новых конфигов

## Используемая библиотека

**V2ray-Android v8.1823**
- Xray core 1.8.23
- Поддержка VLESS, VMESS, Shadowsocks, Trojan, Socks5
- Готовый VPN сервис
- Автоматическое управление разрешениями

## Как использовать

### 1. Добавление конфига

```kotlin
// В UI
VpnScreen -> Кнопка "+" -> Ввести название и VLESS URL
```

### 2. Проверка доступности

```kotlin
// Нажать кнопку обновления (🔄) рядом с конфигом
// Результат: "✓ 45ms • 10с назад" или "✗ Недоступен"
```

### 3. Подключение

```kotlin
// Выбрать конфиг (нажать на него)
// Нажать кнопку "Подключить"
// Система запросит разрешение VPN (первый раз)
// VPN подключится автоматически
```

### 4. Отключение

```kotlin
// Нажать кнопку "Отключить"
```

## Формат VLESS URL

```
vless://UUID@SERVER:PORT?encryption=none&security=tls&sni=DOMAIN&type=ws&path=/PATH&host=HOST
```

### Примеры:

**VLESS + TLS + WebSocket:**
```
vless://12345678-1234-1234-1234-123456789012@example.com:443?encryption=none&security=tls&type=ws&path=/ws&host=example.com
```

**VLESS + Reality:**
```
vless://uuid@server:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.google.com&fp=chrome&pbk=publickey&sid=shortid&type=tcp
```

**VMESS:**
```
vmess://base64encodedconfig
```

## Программное использование

```kotlin
// Инициализация (в MainActivity)
V2rayManager.initialize(context)

// Получить версию ядра
val version = V2rayManager.getCoreVersion()
// Результат: "Xray 1.8.23 (Xray, Penetrates Everything.)"

// Получить статус
val state = V2rayManager.getConnectionState()
// Результат: CONNECTED, CONNECTING, или DISCONNECTED

// Запустить VPN
val success = V2rayManager.startVpn(
    context,
    remark = "My Server",
    config = vlessUrl
)

// Остановить VPN
V2rayManager.stopVpn(context)

// Пинг сервера
val result = VpnPinger.pingVlessServer(vlessUrl)
if (result.isReachable) {
    println("Latency: ${result.latency}ms")
}
```

## Поддерживаемые протоколы

- ✅ VLESS (все транспорты)
- ✅ VMESS
- ✅ Shadowsocks
- ✅ Trojan
- ✅ Socks5
- ✅ HTTP/HTTPS прокси

## Поддерживаемые транспорты

- ✅ TCP
- ✅ WebSocket (WS)
- ✅ HTTP/2 (H2)
- ✅ gRPC
- ✅ QUIC
- ✅ mKCP

## Поддерживаемые TLS

- ✅ TLS 1.3
- ✅ Reality (Xray)
- ✅ uTLS fingerprinting

## Особенности

1. **Автоматическое управление разрешениями**
   - Библиотека сама запрашивает VPN разрешение
   - Не нужно вручную обрабатывать VpnService.prepare()

2. **Уведомления**
   - Автоматическое уведомление при подключении
   - Показывает название сервера
   - Кнопка отключения в уведомлении

3. **Роутинг**
   - Поддержка bypass для приложений
   - Поддержка bypass для подсетей
   - Настраиваемые правила маршрутизации

4. **DNS**
   - Настраиваемые DNS серверы
   - DNS over HTTPS (DoH)
   - DNS over TLS (DoT)

## Требования

- Android API 23+ (Android 6.0+)
- Разрешения:
  - `INTERNET` - для сетевого доступа
  - `BIND_VPN_SERVICE` - для VPN
  - `FOREGROUND_SERVICE` - для фонового сервиса
  - `POST_NOTIFICATIONS` - для уведомлений (Android 13+)

## Сборка

```bash
cd serverSpaceEXCHANGE/JemmyAndroid
./gradlew assembleDebug
```

APK: `app/build/outputs/apk/debug/app-debug.apk`

## Архитектура

```
MainActivity
    └─> V2rayManager.initialize()
    
VpnScreen
    ├─> VpnConfigManager (управление конфигами)
    ├─> VpnPinger (проверка доступности)
    └─> V2rayManager (подключение/отключение)
    
V2rayManager
    └─> V2rayController (из библиотеки)
        └─> Xray Core (нативная библиотека)
```

## Troubleshooting

**VPN не подключается:**
- Проверьте правильность VLESS URL
- Проверьте доступность сервера (пинг)
- Проверьте интернет соединение
- Посмотрите логи: `adb logcat | grep V2ray`

**Пинг не работает:**
- Проверьте интернет соединение
- Убедитесь что порт открыт
- Попробуйте другую сеть

**Приложение крашится:**
- Проверьте что `extractNativeLibs="true"` в манифесте
- Проверьте что библиотека правильно подключена
- Очистите кэш: `./gradlew clean`

## Известные ограничения

1. **Размер APK:**
   - Библиотека добавляет ~30MB к размеру APK
   - Содержит нативные библиотеки для всех архитектур

2. **Батарея:**
   - VPN потребляет батарею
   - Рекомендуется оптимизировать настройки

3. **Совместимость:**
   - Некоторые устройства могут иметь проблемы с VPN
   - Xiaomi/MIUI требует дополнительных разрешений

## Дополнительные возможности

### Bypass приложений

```kotlin
V2rayManager.startVpn(
    context,
    remark = "My Server",
    config = vlessUrl,
    bypassApps = listOf("com.example.app1", "com.example.app2")
)
```

### Bypass подсетей

```kotlin
val bypassSubnets = listOf(
    "192.168.0.0/16",
    "10.0.0.0/8"
)
```

### Кастомный JSON конфиг

Вместо VLESS URL можно передать полный JSON конфиг:

```kotlin
val jsonConfig = """
{
  "log": {"loglevel": "warning"},
  "inbounds": [...],
  "outbounds": [...]
}
"""

V2rayManager.startVpn(context, "Server", jsonConfig)
```

## Ссылки

- [V2ray-Android GitHub](https://github.com/dev7dev/V2ray-Android)
- [Xray Core](https://github.com/xtls/xray-core)
- [V2Ray Documentation](https://www.v2ray.com/)
- [VLESS Protocol](https://xtls.github.io/config/outbounds/vless.html)

## Лицензия

Библиотека V2ray-Android использует Xray core, который распространяется под лицензией MPL 2.0.
