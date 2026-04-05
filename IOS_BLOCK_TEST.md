# Тестирование блокировки на iOS

## Подготовка

1. Перезапустите сервер:
```bash
cd JEMMY-SERVER
npm run start:dev
```

2. Пересоберите iOS приложение в Xcode

## Тест 1: Блокировка пользователя

1. Откройте профиль любого пользователя
2. Нажмите "Заблокировать"
3. Подтвердите действие
4. Проверьте логи в консоли Xcode:
   ```
   📡 Request: POST /identity/block
   ✅ User blocked successfully
   ✅ UI updated: isBlocked = true
   ```

## Тест 2: Проверка статуса блокировки

1. Закройте и снова откройте профиль заблокированного пользователя
2. Проверьте логи:
   ```
   📡 Request: GET /identity/blocked-list/{your_id}
   📥 Raw response: {"blocked_users":[...]}
   ✅ Blocked users loaded: 1
   🚫 User IS BLOCKED
   ```
3. Кнопка должна показывать "Разблокировать"

## Тест 3: Разблокировка пользователя

1. В профиле заблокированного пользователя нажмите "Разблокировать"
2. Подтвердите действие
3. Проверьте логи:
   ```
   📡 Request: POST /identity/unblock
   ✅ Unblock API call successful
   ✅ UI updated: isBlocked = false
   ```

## Тест 4: Список заблокированных

1. Откройте Настройки → Приватность → Заблокированные пользователи
2. Заблокируйте несколько пользователей
3. Проверьте, что все они отображаются в списке
4. Разблокируйте одного из списка
5. Проверьте, что он исчез из списка

## Ожидаемые логи при успешной работе

### При загрузке списка заблокированных:
```
📡 Request: GET /identity/blocked-list/{identity_id}
📥 Response: 200
📥 Raw response: {"blocked_users":[{"_id":"...","username":"...","avatar":"...","bio":"..."}]}
✅ Blocked users loaded: X
```

### При блокировке:
```
🚫 Attempting to block user {username} (ID: {id})
📡 Request: POST /identity/block
✅ Block API call successful
✅ UI updated: isBlocked = true
```

### При разблокировке:
```
✅ Attempting to unblock user {username} (ID: {id})
📡 Request: POST /identity/unblock
✅ Unblock API call successful
✅ UI updated: isBlocked = false
```

## Возможные ошибки

### Ошибка: "keyNotFound"
Если видите:
```
❌ Failed to check blocked status: keyNotFound(...)
❌ Key 'blocked_users' not found
```

Проверьте:
1. Сервер обновлен и перезапущен
2. Метод `getBlockedUsers` в `identity.service.ts` использует `.lean()`
3. Контроллер возвращает `{ blocked_users: [...] }`

### Ошибка: "Cannot decode Identity"
Если видите проблемы с декодированием Identity:
```
❌ Type mismatch: expected String
```

Проверьте:
1. Модель Identity поддерживает оба поля `_id` и `id`
2. Сервер правильно сериализует `_id` как строку

## Сравнение с Android

Поведение должно быть идентичным:
- ✅ Блокировка работает мгновенно
- ✅ Статус сохраняется после перезапуска
- ✅ Список обновляется в реальном времени
- ✅ WebSocket получает обновления о блокировке
