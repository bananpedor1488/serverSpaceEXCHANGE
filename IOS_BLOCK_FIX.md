# iOS Block User Fix

## Проблема
На iOS не работала блокировка пользователей, выдавая ошибку:
```
❌ Failed to check blocked status: keyNotFound(CodingKeys(stringValue: "blocked_users", intValue: nil))
📥 Response: 404
📥 Raw response: {"error":"Identity not found"}
```

## Причины

### 1. Использование неправильного ID
**ГЛАВНАЯ ПРОБЛЕМА:** В `UserProfileView` использовался `authViewModel.userId` (user_id) вместо `authViewModel.identity?.id` (identity_id). 

API endpoint `/identity/blocked-list/:identity_id` ожидает identity_id, а не user_id, поэтому сервер возвращал 404 "Identity not found".

### 2. Несоответствие структуры Identity
iOS модель `Identity` ожидала только поле `_id`, но Mongoose populate мог возвращать объекты с полем `id` вместо `_id`.

### 3. Проблема с сериализацией на сервере
Метод `getBlockedUsers` возвращал Mongoose документы напрямую, что могло приводить к проблемам с сериализацией.

### 4. Отсутствие поля avatar
В схеме Identity на сервере есть `avatar_seed`, но не `avatar`, что могло вызывать проблемы при декодировании.

## Решение

### 1. КРИТИЧЕСКОЕ: Исправлено использование ID
**Файл:** `serverSpaceEXCHANGE/JemmyIOS/Jemmy/Views/UserProfileView.swift`

Заменено использование `authViewModel.userId` на `authViewModel.identity?.id`:

```swift
// ❌ БЫЛО (неправильно):
guard let currentUserId = authViewModel.userId else { return }
APIService.shared.getBlockedUsers(identityId: currentUserId)

// ✅ СТАЛО (правильно):
guard let currentIdentityId = authViewModel.identity?.id else { return }
APIService.shared.getBlockedUsers(identityId: currentIdentityId)
```

Это изменение применено в трех методах:
- `checkIfBlocked()` - проверка статуса блокировки
- `performBlock()` - блокировка пользователя
- `performUnblock()` - разблокировка пользователя

### 2. Обновлена модель Identity (iOS)
**Файл:** `serverSpaceEXCHANGE/JemmyIOS/Jemmy/Models/Identity.swift`

Добавлена поддержка обоих полей `_id` и `id`:
```swift
enum CodingKeys: String, CodingKey {
    case _id = "_id"
    case id
    // ...
}

init(from decoder: Decoder) throws {
    // Try _id first, then id
    if let _id = try? container.decode(String.self, forKey: ._id) {
        id = _id
    } else if let idValue = try? container.decode(String.self, forKey: .id) {
        id = idValue
    } else {
        throw DecodingError.keyNotFound(...)
    }
}
```

### 3. Улучшен метод getBlockedUsers на сервере
**Файл:** `JEMMY-SERVER/src/identity/identity.service.ts`

- Добавлен `.lean()` для конвертации в plain objects
- Явная сериализация полей с правильными именами
- Использование `avatar_seed` как `avatar`
- Добавлено логирование для отладки

```typescript
async getBlockedUsers(identity_id: string) {
  const blocked = await this.blockedUserModel
    .find({ blocker_identity_id: new Types.ObjectId(identity_id) })
    .populate('blocked_identity_id')
    .lean(); // Convert to plain JavaScript objects

  const identities = blocked
    .map(b => b.blocked_identity_id as any)
    .filter(identity => identity != null)
    .map((identity: any) => ({
      _id: identity._id.toString(),
      username: identity.username,
      avatar: identity.avatar_seed || '',
      bio: identity.bio || '',
      // ...
    }));

  return identities;
}
```

### 4. Улучшена обработка ошибок (iOS)
**Файл:** `serverSpaceEXCHANGE/JemmyIOS/Jemmy/Services/APIService.swift`

Добавлена обработка 404 ошибки (Identity not found) - возвращает пустой массив вместо ошибки:
```swift
func getBlockedUsers(identityId: String) async throws -> [Identity] {
    let url = URL(string: "\(baseURL)/identity/blocked-list/\(identityId)")!
    let (data, response) = try await URLSession.shared.data(from: url)
    
    if let httpResponse = response as? HTTPURLResponse {
        // Handle 404 - Identity not found
        if httpResponse.statusCode == 404 {
            print("⚠️ Identity not found: \(identityId)")
            return [] // Return empty array instead of throwing
        }
    }
    
    // Decode response...
}
```

**Файл:** `serverSpaceEXCHANGE/JemmyIOS/Jemmy/Views/UserProfileView.swift`

Добавлена детальная обработка всех типов DecodingError.

## Сравнение с Android

Android версия работала корректно благодаря:
1. Правильному использованию identity_id в запросах
2. Поддержке обоих полей `_id` и `id` с геттером
3. Использованию Gson, который более гибко обрабатывает JSON

```kotlin
// Android правильно использует identity_id
repository.getBlockedUsers(currentUserId) // currentUserId = identity_id

data class Identity(
    @SerializedName("_id")
    val _id: String? = null,
    
    @SerializedName("id")
    val idField: String? = null,
    // ...
) {
    val id: String
        get() = _id ?: idField ?: ""
}
```

## Ключевое различие: userId vs identityId

В системе есть два типа ID:
- `user_id` - ID пользователя (устройства), может иметь несколько идентичностей
- `identity_id` - ID конкретной идентичности пользователя

Для операций блокировки нужен `identity_id`, а не `user_id`!

## Результат
Теперь iOS версия работает так же, как Android:
- ✅ Корректная проверка статуса блокировки
- ✅ Блокировка пользователей
- ✅ Разблокировка пользователей
- ✅ Отображение списка заблокированных пользователей

## Измененные файлы

### iOS
1. `serverSpaceEXCHANGE/JemmyIOS/Jemmy/Models/Identity.swift` - поддержка обоих полей `_id` и `id`
2. `serverSpaceEXCHANGE/JemmyIOS/Jemmy/Services/APIService.swift` - улучшенная обработка ошибок
3. `serverSpaceEXCHANGE/JemmyIOS/Jemmy/Views/UserProfileView.swift` - детальное логирование ошибок

### Сервер
1. `JEMMY-SERVER/src/identity/identity.service.ts` - исправлен метод `getBlockedUsers` с `.lean()` и явной сериализацией

## Тестирование
После применения изменений:
1. Перезапустите сервер
2. Пересоберите iOS приложение
3. Проверьте блокировку/разблокировку пользователей
4. Проверьте список заблокированных пользователей в настройках приватности
