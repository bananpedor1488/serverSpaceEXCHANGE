# Защита от скриншотов

## iOS - ✅ РЕАЛИЗОВАНО

### Как работает
1. Пользователь включает "Защита от скриншотов" в настройках приватности
2. Настройка сохраняется на сервере в `privacy_settings.screenshot_protection`
3. Когда собеседник открывает чат, загружаются настройки приватности
4. Если защита включена:
   - Показывается системное сообщение в чате
   - При попытке сделать скриншот или начать запись экрана - контент размывается и показывается предупреждение

### Технические детали

**Модификатор**: `ScreenshotProtectionModifier`
- Отслеживает `UIApplication.userDidTakeScreenshotNotification`
- Отслеживает `UIScreen.capturedDidChangeNotification` (запись экрана)
- При активации - размывает контент и показывает overlay

**Файлы**:
- `JemmyIOS/Jemmy/Utils/ScreenshotProtection.swift` - модификатор защиты
- `JemmyIOS/Jemmy/Views/ChatView.swift` - применение защиты
- `JemmyIOS/Jemmy/Views/HomeView.swift` - настройки (строка ~690)
- `JemmyIOS/Jemmy/Models/Identity.swift` - модель PrivacySettings

**Серверная часть**:
- `JEMMY-SERVER/server.js` - поле `screenshot_protection` в схеме Identity

### Использование
```swift
// Применить защиту к любому View
SomeView()
    .screenshotProtection(enabled: true)
```

## Android - ❌ НЕ РЕАЛИЗОВАНО

### План реализации
1. Добавить `FLAG_SECURE` к окну активности
2. Создать PrivacyManager для Android
3. Загружать настройки собеседника в ChatScreen
4. Показывать системное сообщение в чате

### Код для Android
```kotlin
// В ChatScreen.kt
if (otherUserPrivacySettings?.screenshotProtection == true) {
    // Включить FLAG_SECURE
    val window = (context as? Activity)?.window
    window?.setFlags(
        WindowManager.LayoutParams.FLAG_SECURE,
        WindowManager.LayoutParams.FLAG_SECURE
    )
}
```

## Тестирование

### iOS
1. Включить защиту от скриншотов в настройках
2. Открыть чат с другого устройства
3. Проверить что показывается системное сообщение
4. Попробовать сделать скриншот - должен размыться экран
5. Начать запись экрана - должен размыться экран

### Ожидаемое поведение
- При скриншоте: экран размывается, показывается overlay с иконкой и текстом
- При записи экрана: экран размывается на всё время записи
- Системное сообщение показывается один раз вверху чата

## Статус
- iOS: ✅ Готово
- Android: ❌ Не реализовано
- Сервер: ✅ Готово
