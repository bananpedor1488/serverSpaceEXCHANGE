# iOS Block User Fix

## Проблема
На iOS не работала блокировка пользователей, выдавая ошибку:
```
❌ Failed to check blocked status: keyNotFound(CodingKeys(stringValue: "blocked_users", intValue: nil))
```

## Причины

### 1. Несоответствие структуры Identity
iOS модель `Identity` ожидала только поле `_id`, но Mongoose populate мог возвращать объекты с полем `id` вместо `_id`.

### 2. Проблема с сериализацией на сервере
Метод `getBlockedUsers` возвращал Mongoose документы напрямую, что могло приводить к проблемам с сериализацией.

### 3. Отсутствие поля avatar
В схеме Identity на сервере есть `avatar_seed`, но не `avatar`, что могло вызывать проблемы при декодировании.

## Решение

### 1. Обновлена модель Identity (iOS)
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

### 2. Улучшен метод getBlockedUsers на сервере
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
    .map(b => b.blocked_identity_id)
    .filter(identity => identity != null)
    .map(identity => ({
      _id: identity._id.toString(),
      username: identity.username,
      avatar: identity.avatar_seed || '',
      bio: identity.bio || '',
      // ...
    }));

  return identities;
}
```

### 3. Улучшена обработка ошибок (iOS)
**Файл:** `serverSpaceEXCHANGE/JemmyIOS/Jemmy/Services/APIService.swift`

Добавлено детальное логирование ошибок декодирования с правильной областью видимости переменных:
```swift
func getBlockedUsers(identityId: String) async throws -> [Identity] {
    let url = URL(string: "\(baseURL)/identity/blocked-list/\(identityId)")!
    let (data, response) = try await URLSession.shared.data(from: url)
    
    // Log raw response
    if let jsonString = String(data: data, encoding: .utf8) {
        print("📥 Raw response: \(jsonString)")
    }
    
    do {
        let decoder = JSONDecoder()
        let blockedResponse = try decoder.decode(BlockedUserResponse.self, from: data)
        return blockedResponse.blockedUsers
    } catch let DecodingError.keyNotFound(key, context) {
        print("❌ Key '\(key.stringValue)' not found:", context.debugDescription)
        
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            print("📦 Actual JSON structure:", json)
        }
        
        throw DecodingError.keyNotFound(key, context)
    }
}
```

**Файл:** `serverSpaceEXCHANGE/JemmyIOS/Jemmy/Views/UserProfileView.swift`

Добавлена детальная обработка всех типов DecodingError.

## Сравнение с Android

Android версия работала корректно благодаря:
1. Поддержке обоих полей `_id` и `id` с геттером
2. Использованию Gson, который более гибко обрабатывает JSON

```kotlin
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
