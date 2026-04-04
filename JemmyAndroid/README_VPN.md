# VPN функционал с AndroidLibXrayLite

## Статус: ✅ Готово к тестированию

Реализован полноценный VPN с поддержкой VLESS протокола на базе официальной библиотеки AndroidLibXrayLite от 2dust (автор v2rayNG).

## Что сделано

### 1. Библиотека AndroidLibXrayLite
- ✅ Файл `libv2ray.aar` (v1.8.13) размещен в `app/libs/`
- ✅ Зависимость добавлена в `app/build.gradle.kts`
- ✅ Настроен `android:extractNativeLibs="true"` в манифесте

### 2. VPN Service
- ✅ `JemmyVpnService.kt` - полноценный VPN сервис
  - Реализует интерфейс `V2RayVPNServiceSupportsSet`
  - Конвертирует VLESS URL в JSON конфиг
  - Управляет VPN подключением через `V2RayPoint`
  - Показывает уведомление о статусе подключения

### 3. Менеджер VPN
- ✅ `V2rayManager.kt` - упрощенный менеджер для работы с сервисом
  - Запуск/остановка VPN
  - Получение версии ядра Xray
  - Проверка статуса подключения

### 4. Управление конфигами
- ✅ `VpnConfigManager.kt` - сохранение/загрузка конфигов
- ✅ `VpnConfig.kt` - модель данных с результатами пинга
- ✅ `VpnPinger.kt` - проверка доступности серверов

### 5. UI
- ✅ `VpnScreen.kt` - главный экран VPN
  - Список конфигов
  - Кнопка подключения/отключения
  - Статус подключения
  - Кнопка пинга для каждого конфига
- ✅ `AddVpnConfigScreen.kt` - добавление новых конфигов
  - Ввод имени и VLESS URL
  - Автоматический пинг после добавления

### 6. Разрешения
- ✅ VPN разрешения в манифесте
- ✅ Запрос VPN разрешения через `VpnService.prepare()`
- ✅ Foreground service для стабильной работы

## Как использовать

### Формат VLESS URL

```
vless://UUID@SERVER:PORT?encryption=none&security=tls&sni=SERVER&type=ws&path=/PATH&host=SERVER#NAME
```

Пример:
```
vless://12345678-1234-1234-1234-123456789abc@example.com:443?encryption=none&security=tls&sni=example.com&type=ws&path=/ws&host=example.com#MyVPN
```

### Добавление конфига

1. Открыть VPN экран
2. Нажать "+" в верхнем правом углу
3. Ввести имя конфига
4. Вставить VLESS URL
5. Нажать "Добавить"
6. Автоматически выполнится пинг

### Подключение к VPN

1. Выбрать конфиг из списка (он станет активным)
2. Нажать кнопку "Подключить"
3. Разрешить VPN подключение (если первый раз)
4. Дождаться подключения

### Проверка сервера

- Нажать кнопку обновления (🔄) рядом с конфигом
- Отобразится пинг в миллисекундах или статус "Недоступен"

## Следующие шаги

### 1. Синхронизация Gradle
```bash
./gradlew clean
./gradlew build
```

### 2. Тестирование
- Добавить тестовый VLESS конфиг
- Проверить пинг
- Попробовать подключиться
- Проверить работу интернета через VPN

### 3. Проверка логов
```bash
adb logcat | grep -E "JemmyVpnService|V2rayManager"
```

## Поддерживаемые протоколы

- ✅ VLESS
- ✅ TCP
- ✅ WebSocket (ws)
- ✅ gRPC
- ✅ TLS
- ✅ Reality (через параметры fp, pbk, sid)

## Структура JSON конфига

Сервис автоматически конвертирует VLESS URL в JSON конфиг Xray:

```json
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "port": 10808,
    "protocol": "socks",
    "settings": { "auth": "noauth", "udp": true }
  }],
  "outbounds": [{
    "protocol": "vless",
    "settings": {
      "vnext": [{
        "address": "server.com",
        "port": 443,
        "users": [{ "id": "uuid", "encryption": "none" }]
      }]
    },
    "streamSettings": {
      "network": "ws",
      "security": "tls",
      "tlsSettings": {
        "serverName": "server.com",
        "fingerprint": "chrome",
        "alpn": ["h2", "http/1.1"]
      },
      "wsSettings": {
        "path": "/path",
        "headers": { "Host": "server.com" }
      }
    }
  }]
}
```

## Troubleshooting

### Ошибка: "Native library not found"
- Проверь что AAR файл в `app/libs/libv2ray.aar`
- Проверь `android:extractNativeLibs="true"` в манифесте
- Выполни `./gradlew clean`

### VPN не подключается
- Проверь формат VLESS URL
- Проверь доступность сервера (пинг)
- Проверь логи: `adb logcat | grep V2Ray`

### Приложение крашится
- Проверь что зависимость `implementation(files("libs/libv2ray.aar"))` раскомментирована
- Синхронизируй Gradle
- Пересобери проект

## Версия библиотеки

- AndroidLibXrayLite: v1.8.13
- Xray-core: встроен в AAR
- Источник: https://github.com/2dust/AndroidLibXrayLite

## Файлы проекта

```
app/
├── libs/
│   └── libv2ray.aar                    # Библиотека Xray
├── src/main/
│   ├── AndroidManifest.xml             # VPN разрешения и сервис
│   └── java/com/bananjemmy/
│       ├── vpn/
│       │   ├── JemmyVpnService.kt      # VPN сервис
│       │   ├── V2rayManager.kt         # Менеджер VPN
│       │   ├── VpnConfigManager.kt     # Управление конфигами
│       │   └── VpnPinger.kt            # Пинг серверов
│       ├── data/model/
│       │   └── VpnConfig.kt            # Модель конфига
│       └── ui/screen/
│           ├── VpnScreen.kt            # Главный экран
│           └── AddVpnConfigScreen.kt   # Добавление конфига
```
