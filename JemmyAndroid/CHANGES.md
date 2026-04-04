# Изменения в проекте

## ✅ Удален VPN функционал

### Удалено:
- ❌ Зависимость `libv2ray.aar` (закомментирована в build.gradle)
- ❌ Импорты VPN классов из MainActivity
- ❌ Кнопка "VPN" из ProfileScreen
- ❌ Навигация `onNavigateToVpn` из всех экранов
- ❌ Экраны `VpnScreen` и `AddVpnConfigScreen` (файлы остались, но не используются)
- ❌ Инициализация V2rayManager

### Файлы которые можно удалить (опционально):
- `app/src/main/java/com/bananjemmy/vpn/` (вся папка)
- `app/src/main/java/com/bananjemmy/ui/screen/VpnScreen.kt`
- `app/src/main/java/com/bananjemmy/ui/screen/AddVpnConfigScreen.kt`
- `app/libs/libv2ray.aar`
- Все VPN документы: `VPN_*.md`, `XRAY_*.md`, `README_VPN.md`

## ✅ Исправлен баг с клавиатурой в чате

### Проблема:
При открытии клавиатуры TextField улетал вверх с огромным зазором между ним и клавиатурой.

### Решение:
1. Убрал `bottomBar` из Scaffold
2. Переместил поле ввода внутрь контента (Column)
3. Добавил `.imePadding()` к Row с TextField - это автоматически добавляет padding когда открывается клавиатура
4. Изменил структуру:
   ```kotlin
   Column {
       Box(weight = 1f) { /* Список сообщений */ }
       Column { /* Поле ввода с imePadding */ }
   }
   ```

### Результат:
- ✅ TextField остается внизу экрана
- ✅ Нет зазора между TextField и клавиатурой
- ✅ Список сообщений автоматически поднимается вверх
- ✅ Плавная анимация при открытии/закрытии клавиатуры

## Сборка

Проект настроен на сборку только для ARM64-v8a:
```kotlin
ndk {
    abiFilters.add("arm64-v8a")
}
```

Это уменьшает размер APK и ускоряет сборку.

## Команды для сборки

Debug:
```bash
./gradlew assembleDebug
```

Release:
```bash
./gradlew assembleRelease
```

Или через Android Studio: Build → Build Bundle(s) / APK(s) → Build APK(s)
