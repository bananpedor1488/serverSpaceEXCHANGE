# ✅ Deep Link Implementation Complete

## Что сделано

### 1. Android
- ✅ Deep link обработка для `https://weeky-six.vercel.app/api/u/{token}`
- ✅ Deep link обработка для `jemmy://invite/{token}`
- ✅ Сохранение токена до авторизации
- ✅ Автоматическая обработка после авторизации
- ✅ Модалка `InviteProfileScreen` с кнопкой "Начать чат"
- ✅ Создание чата через API
- ✅ Подробное логирование для отладки
- ✅ Toast уведомления для визуальной отладки

### 2. iOS/macOS
- ✅ Deep link обработка для обеих схем
- ✅ Associated Domains в entitlements
- ✅ Модалка с профилем пользователя

### 3. Server
- ✅ Endpoint `/api/identity/invite/preview/{token}` (новый)
- ✅ Endpoint `/api/invite/preview/{token}` (старый, для совместимости)
- ✅ Endpoint `/api/identity/generate-link` для генерации ссылок
- ✅ Endpoint `/api/chat/start` для создания чата по токену

## 🚀 Деплой

### Сервер
```bash
cd JEMMY-SERVER
vercel --prod
```

### Android
```bash
cd JemmyAndroid
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## 🧪 Тестирование

### 1. Генерация ссылки
- Откройте приложение
- Профиль → "Создать ссылку"
- Скопируйте ссылку

### 2. Тест через ADB
```bash
adb shell am start -a android.intent.action.VIEW -d "https://weeky-six.vercel.app/api/u/YOUR_TOKEN"
```

### 3. Проверка логов
```bash
adb logcat | findstr "MainActivity ChatViewModel"
```

### 4. Ожидаемое поведение
1. Приложение открывается
2. Появляется toast "🔗 Processing invite: TOKEN"
3. Появляется toast "✅ Loaded: username"
4. Появляется модалка с профилем и кнопкой "Начать чат"
5. После нажатия создается чат
6. Открывается экран чата

## 📋 Логи для проверки

```
MainActivity: 🔗 Deep link received: https://weeky-six.vercel.app/api/u/TOKEN
MainActivity: ✅ Extracted token from HTTPS link: TOKEN
MainActivity: 🔄 LaunchedEffect triggered
MainActivity:    authState: Authenticated
MainActivity:    pendingToken: TOKEN
MainActivity: 🔗 Processing pending deep link after auth: TOKEN
MainActivity: ✅ Processing deep link token: TOKEN
MainActivity: 📡 Calling previewInviteLink API...
JemmyRepository: Response code: 200
JemmyRepository: Response successful: true
MainActivity: ✅ Invite preview loaded: username
ChatViewModel: 🎯 setPendingInvite called
ChatViewModel: ✅ pendingInvite updated: true
MainScreen: 🔔 pendingInvite changed: true
```

## ❌ Troubleshooting

### Проблема: 404 на `/api/identity/invite/preview/{token}`
**Решение:** Задеплойте сервер заново:
```bash
cd JEMMY-SERVER
vercel --prod
```

### Проблема: Модалка не появляется
**Решение:** Проверьте логи - должен быть "pendingInvite changed: true"

### Проблема: Токен не извлекается
**Решение:** Проверьте формат ссылки - должна быть `/api/u/TOKEN`

### Проблема: Приложение не открывается
**Решение:** 
1. Проверьте AndroidManifest.xml - должен быть intent-filter
2. Очистите данные приложения: `adb shell pm clear com.bananjemmy`
3. Переустановите приложение

## 🔗 API Endpoints

### Preview Invite (не расходует использование)
```
GET /api/identity/invite/preview/{token}
GET /api/invite/preview/{token}  (старый путь)
```

Response:
```json
{
  "identity": {
    "_id": "...",
    "username": "...",
    "avatar": "...",
    "bio": "..."
  },
  "uses_left": 5
}
```

### Generate Link
```
POST /api/identity/generate-link
Body: { "identity_id": "..." }
```

Response:
```json
{
  "url": "https://weeky-six.vercel.app/api/u/TOKEN"
}
```

### Start Chat
```
POST /api/chat/start
Body: { "token": "...", "my_identity_id": "..." }
```

Response:
```json
{
  "chat_id": "...",
  "other_user": {
    "_id": "...",
    "username": "...",
    "avatar": "...",
    "bio": "..."
  }
}
```

## 📱 Поддерживаемые форматы ссылок

1. **HTTPS (Universal Links):** `https://weeky-six.vercel.app/api/u/{token}`
2. **Custom scheme:** `jemmy://invite/{token}`

Оба формата работают одинаково и открывают приложение с модалкой.
