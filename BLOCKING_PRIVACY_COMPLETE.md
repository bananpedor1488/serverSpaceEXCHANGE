# Блокировка и приватность - Завершено

## Реализованные функции

### 1. Вкладка "Заблокированные" в настройках приватности (Android)

Добавлена кнопка в `PrivacySettingsScreen` для перехода к списку заблокированных пользователей.

**Файлы:**
- `PrivacySettingsScreen.kt` - добавлена секция "Блокировка" с кнопкой навигации
- `MainActivity.kt` - добавлен Dialog для `BlockedUsersScreen`

### 2. Скрытие аватарки и статуса для заблокировавших пользователей

Когда пользователь заблокирован другим пользователем:
- Аватарка заменяется на placeholder (серый круг с иконкой)
- Статус всегда показывает "был(а) давно"
- Реальный онлайн-статус и время последнего визита скрыты

**Реализовано на обеих платформах:**

#### Android
**Файлы:**
- `ContactProfileScreen.kt` - проверка `amIBlocked` и условное отображение
- `JemmyRepository.kt` - метод `amIBlockedBy()`
- `JemmyApiService.kt` - endpoint `/api/identity/am-i-blocked/{my_id}/{other_id}`
- `Identity.kt` - модель `AmIBlockedResponse`

#### iOS
**Файлы:**
- `UserProfileView.swift` - проверка `amIBlocked` и условное отображение
- `APIService.swift` - метод `amIBlocked()`

#### Сервер
**Файлы:**
- `identity.service.ts` - метод `isBlockedBy()`
- `identity.controller.ts` - endpoint `GET /identity/am-i-blocked/:my_id/:other_id`

## API Endpoints

### Новый endpoint
```
GET /api/identity/am-i-blocked/:my_id/:other_id
```

**Ответ:**
```json
{
  "is_blocked": true/false
}
```

**Описание:** Проверяет, заблокирован ли `my_id` пользователем `other_id`.

## Логика работы

### Проверка блокировки
1. При открытии профиля пользователя выполняются два запроса:
   - `getBlockedUsers()` - проверка, заблокирован ли этот пользователь мной
   - `amIBlocked()` - проверка, заблокирован ли я этим пользователем

2. На основе результатов:
   - Если `isBlocked = true` - показывается кнопка "Разблокировать"
   - Если `amIBlocked = true` - скрывается аватарка и статус

### Отображение для заблокировавших

**Android:**
```kotlin
if (amIBlocked) {
    // Placeholder avatar
    Surface(
        modifier = Modifier.size(100.dp),
        shape = CircleShape,
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Icon(imageVector = Icons.Filled.AccountBox, ...)
    }
    
    // Static status
    Text(text = "был(а) давно")
}
```

**iOS:**
```swift
if amIBlocked {
    // Placeholder avatar
    Circle()
        .fill(Color.white.opacity(0.1))
        .overlay(
            Image(systemName: "person.fill")
        )
    
    // Static status
    Text("был(а) давно")
}
```

## Навигация (Android)

Настройки → Приватность → Заблокированные пользователи

```
ProfileScreen
  ↓
PrivacySettingsScreen
  ↓ (нажатие на "Заблокированные пользователи")
BlockedUsersScreen
```

## Тестирование

### Тест 1: Навигация к заблокированным (Android)
1. Откройте профиль
2. Нажмите "Приватность"
3. Нажмите "Заблокированные пользователи"
4. Должен открыться список заблокированных

### Тест 2: Скрытие аватарки
1. Пользователь A блокирует пользователя B
2. Пользователь B открывает профиль пользователя A
3. Должна отображаться placeholder аватарка
4. Статус должен быть "был(а) давно"

### Тест 3: Восстановление после разблокировки
1. Пользователь A разблокирует пользователя B
2. Пользователь B обновляет профиль пользователя A
3. Аватарка и реальный статус должны восстановиться

## Приватность

Эта функция обеспечивает:
- Защиту приватности заблокировавшего пользователя
- Невозможность отслеживания онлайн-статуса заблокированным
- Скрытие аватарки от нежелательных контактов

## Совместимость

- ✅ Android - полностью реализовано
- ✅ iOS - полностью реализовано
- ✅ Сервер - API готов
- ⚠️ Mac - требует аналогичной реализации (TODO)
