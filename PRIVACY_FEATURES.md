# 🔐 Privacy Features Implementation

## Реализованные функции конфиденциальности

### 📱 ЛОКАЛЬНЫЕ (iOS)

#### 1. Блокировка приложения
- **PIN-код (4 цифры)**
  - Установка/изменение/удаление PIN
  - Хранение в Keychain (безопасно)
  - Файл: `PinCodeSetupView.swift`

- **Биометрическая аутентификация**
  - Face ID / Touch ID
  - Автоматическое определение типа биометрии
  - Файл: `PrivacyManager.swift`

#### 2. Автоблокировка
- Настройка времени: 1, 5, 10, 30, 60 минут
- Автоматическая блокировка при неактивности
- Файл: `AutoLockSettingsView.swift`

#### 3. Скрытие контента уведомлений
- Показывать только "Новое сообщение"
- Скрывать текст и имя отправителя
- Управление через `PrivacyManager`

#### 4. Защита от скриншотов
- Запрет скриншотов в чатах
- Уведомление при попытке
- Управление через `PrivacyManager`

### 🌐 СЕРВЕРНЫЕ

#### 5. Кто может писать мне
- Варианты: Все / Контакты / Никто
- Проверка на сервере перед отправкой сообщения
- Endpoint: `GET /identity/can-message/:from_id/:to_id`

#### 6. Кто видит мой профиль
- Варианты: Все / Контакты / Никто
- Фильтрация при просмотре профиля
- Endpoint: `GET /identity/can-see-profile/:viewer_id/:target_id`

#### 7. Кто видит статус "онлайн"
- Варианты: Все / Контакты / Никто
- Скрытие зеленого индикатора
- Хранится в `privacy_settings.who_can_see_online`

#### 8. Кто видит "последний раз в сети"
- Варианты: Все / Контакты / Никто
- Скрытие времени последней активности
- Хранится в `privacy_settings.who_can_see_last_seen`

#### 9. Автоудаление сообщений
- Варианты: Выключено / 24ч / 7 дней / 30 дней
- Автоматическое удаление старых сообщений
- Файл: `AutoDeleteSettingsView.swift`

#### 10. Заблокированные пользователи
- Список заблокированных
- Блокировка/разблокировка
- Файл: `BlockedUsersView.swift`
- Endpoints:
  - `POST /identity/block`
  - `POST /identity/unblock`
  - `GET /identity/blocked-list/:identity_id`

---

## 📊 Структура данных

### Identity Schema (MongoDB)
```typescript
privacy_settings: {
  who_can_message: 'everyone' | 'contacts' | 'nobody',
  who_can_see_profile: 'everyone' | 'contacts' | 'nobody',
  who_can_see_online: 'everyone' | 'contacts' | 'nobody',
  who_can_see_last_seen: 'everyone' | 'contacts' | 'nobody',
  auto_delete_messages: 0 | 24 | 168 | 720, // hours
}
```

### BlockedUser Schema (MongoDB)
```typescript
{
  blocker_identity_id: ObjectId,
  blocked_identity_id: ObjectId,
  blocked_at: Date
}
```

---

## 🎯 API Endpoints

### Privacy Settings
- `PATCH /identity/privacy/update` - Обновить настройки приватности
- `GET /identity/privacy/:identity_id` - Получить настройки приватности

### Blocked Users
- `POST /identity/block` - Заблокировать пользователя
- `POST /identity/unblock` - Разблокировать пользователя
- `GET /identity/blocked-list/:identity_id` - Список заблокированных

### Permission Checks
- `GET /identity/can-message/:from_id/:to_id` - Может ли писать
- `GET /identity/can-see-profile/:viewer_id/:target_id` - Может ли видеть профиль

---

## 📁 Файлы

### Backend (NestJS)
- `src/schemas/identity.schema.ts` - Добавлено поле `privacy_settings`
- `src/schemas/blocked-user.schema.ts` - Новая схема для блокировки
- `src/identity/identity.service.ts` - Методы для работы с приватностью
- `src/identity/identity.controller.ts` - API endpoints
- `src/identity/identity.module.ts` - Регистрация BlockedUser схемы

### iOS Client
- `Models/Identity.swift` - Модели `PrivacySettings`, `PrivacyOption`
- `Services/PrivacyManager.swift` - Менеджер локальной безопасности
- `Services/APIService.swift` - API методы для приватности
- `Views/HomeView.swift` - Обновленный `PrivacySettingsView`
- `Views/PinCodeSetupView.swift` - Настройка PIN-кода
- `Views/AutoLockSettingsView.swift` - Настройка автоблокировки
- `Views/BlockedUsersView.swift` - Список заблокированных

---

## ✅ Как использовать

### Локальная безопасность
1. Открыть Профиль → Приватность
2. Настроить PIN-код
3. Включить Face ID / Touch ID
4. Настроить автоблокировку
5. Включить скрытие уведомлений

### Серверные настройки
1. Открыть Профиль → Приватность
2. Настроить "Кто может писать"
3. Настроить видимость профиля
4. Настроить видимость статуса
5. Настроить автоудаление сообщений

### Блокировка пользователей
1. Открыть профиль пользователя
2. Нажать "Заблокировать"
3. Или: Приватность → Заблокированные → Управление списком

---

## 🔒 Безопасность

- PIN-код хранится в iOS Keychain (зашифрован)
- Биометрия использует LocalAuthentication framework
- Все настройки синхронизируются с сервером
- Блокировка работает двусторонне
- Проверки приватности на стороне сервера

---

## 🚀 Следующие шаги

1. Добавить систему контактов для опции "Контакты"
2. Реализовать автоудаление сообщений (cron job)
3. Добавить уведомления о попытках скриншотов
4. Добавить двухфакторную аутентификацию (2FA)
5. Добавить шифрование локальной БД
