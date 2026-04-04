# Deep Link Fix - Модалка "Начать чат"

## ✅ Что исправлено

### Android
1. **Сохранение токена до авторизации** - токен из deep link сохраняется в `pendingDeepLinkToken` и обрабатывается ПОСЛЕ авторизации
2. **Правильная привязка к ViewModel** - `MainScreen` использует `pendingInvite` напрямую из `ChatViewModel`
3. **Улучшенное логирование** - добавлены подробные логи для отладки всего процесса
4. **Обработка в правильном контексте** - deep link обрабатывается в `MainActivity.setContent`, где доступны все переменные

### Логика работы
```
1. Пользователь кликает ссылку https://weeky-six.vercel.app/api/u/{token}
2. Android открывает приложение → onCreate() или onNewIntent()
3. extractTokenFromIntent() извлекает token и сохраняет в pendingDeepLinkToken
4. Приложение проходит авторизацию (если нужно)
5. LaunchedEffect следит за authState
6. Когда authState становится Authenticated, вызывается processDeepLinkToken()
7. API загружает данные пользователя через previewInviteLink()
8. chatViewModel.setPendingInvite() устанавливает данные
9. MainScreen видит изменение pendingInvite через collectAsStateWithLifecycle()
10. Появляется Dialog с InviteProfileScreen
11. Пользователь нажимает "Начать чат"
12. Создается чат через startChatByInvite() и открывается
```

## 🔍 Логи для проверки

Смотрите в Logcat (фильтр: `MainActivity` или `ChatViewModel`):
```
MainActivity: 🔗 Deep link received: https://weeky-six.vercel.app/api/u/abc123
MainActivity: ✅ Extracted token from HTTPS link: abc123
MainActivity: 🔗 Processing pending deep link after auth: abc123
MainActivity: ✅ Processing deep link token: abc123
MainActivity: 📡 Calling previewInviteLink API...
MainActivity: ✅ Invite preview loaded: username
MainActivity: 🎯 Setting pendingInvite in ViewModel
ChatViewModel: 🎯 setPendingInvite called
ChatViewModel:    Identity: username
ChatViewModel:    Token: abc123
ChatViewModel: ✅ pendingInvite updated: true
MainScreen: 🔔 pendingInvite changed: true
MainScreen:    Identity: username
MainScreen:    Token: abc123
```

## 🧪 Тестирование

### 1. Генерация ссылки
- Откройте профиль → "Создать ссылку"
- Скопируйте ссылку вида `https://weeky-six.vercel.app/api/u/abc123`

### 2. Тест через ADB
```bash
# Замените YOUR_TOKEN на реальный токен
adb shell am start -a android.intent.action.VIEW -d "https://weeky-six.vercel.app/api/u/YOUR_TOKEN"
```

### 3. Тест через браузер
- Отправьте ссылку себе в Telegram/WhatsApp
- Кликните по ссылке на телефоне
- Выберите "Открыть в Jemmy"

### 4. Тест с jemmy:// схемой
```bash
adb shell am start -a android.intent.action.VIEW -d "jemmy://invite/YOUR_TOKEN"
```

## ❗ Важно

1. **Manifest** - уже настроен правильно с `android:autoVerify="true"` и `android:launchMode="singleTask"`
2. **apple-app-site-association** - файл должен быть доступен по `https://weeky-six.vercel.app/.well-known/apple-app-site-association`
3. **Токен одноразовый** - после создания чата токен может стать недействительным (зависит от серверной логики)

## 🐛 Если не работает

### 1. Проверьте логи
Должны быть ВСЕ сообщения из списка выше. Если какого-то нет:
- Нет "Deep link received" → проблема с Manifest или deep link не передается
- Нет "Extracted token" → проблема с парсингом URL
- Нет "Processing pending" → пользователь не авторизован или LaunchedEffect не срабатывает
- Нет "Invite preview loaded" → проблема с API или сетью
- Нет "pendingInvite updated" → проблема с ViewModel
- Нет "pendingInvite changed" → проблема с collectAsStateWithLifecycle в MainScreen

### 2. Проверьте API
```bash
curl https://weeky-six.vercel.app/api/invite/preview/YOUR_TOKEN
```
Должен вернуть JSON с полем `identity`

### 3. Проверьте авторизацию
Убедитесь что пользователь авторизован перед обработкой токена. Если нет - токен будет обработан после авторизации.

### 4. Очистите кеш приложения
```bash
adb shell pm clear com.bananjemmy
```

## 📱 Поддерживаемые форматы ссылок

1. **HTTPS** (Universal Links): `https://weeky-six.vercel.app/api/u/{token}`
2. **Custom scheme**: `jemmy://invite/{token}`

Оба формата работают одинаково.
