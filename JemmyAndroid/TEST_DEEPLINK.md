# Тестирование Deep Link

## 🧪 Шаги для тестирования

### 1. Соберите и установите приложение
```bash
cd JemmyAndroid
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### 2. Сгенерируйте ссылку
- Откройте приложение
- Перейдите в Профиль
- Нажмите "Создать ссылку"
- Скопируйте ссылку (например: `https://weeky-six.vercel.app/api/u/abc123xyz`)

### 3. Тест через ADB
```bash
# Замените TOKEN на ваш реальный токен
adb shell am start -a android.intent.action.VIEW -d "https://weeky-six.vercel.app/api/u/TOKEN"
```

### 4. Что должно произойти

1. **Приложение откроется**
2. **Появятся тосты:**
   - "🔗 Processing invite: TOKEN"
   - "✅ Loaded: username"
3. **Появится модалка** с профилем пользователя и кнопкой "Начать чат"

### 5. Проверка логов

Откройте новый терминал и запустите:
```bash
adb logcat | findstr "MainActivity ChatViewModel MainScreen"
```

Или используйте скрипт:
```bash
.\check-logs.ps1
```

## 📋 Ожидаемые логи

```
MainActivity: 🚀 onCreate started
MainActivity: 🔗 Deep link received: https://weeky-six.vercel.app/api/u/TOKEN
MainActivity: ✅ Extracted token from HTTPS link: TOKEN
MainActivity: 🔗 Deep link token found in onCreate: TOKEN
MainActivity: 🔄 LaunchedEffect triggered
MainActivity:    authState: Authenticated
MainActivity:    pendingToken: TOKEN
MainActivity: 🔗 Processing pending deep link after auth: TOKEN
MainActivity: ✅ Processing deep link token: TOKEN
MainActivity: 📡 Calling previewInviteLink API...
MainActivity: ✅ Invite preview loaded: username
MainActivity: 🎯 Setting pendingInvite in ViewModel
ChatViewModel: 🎯 setPendingInvite called
ChatViewModel:    Identity: username
ChatViewModel:    Token: TOKEN
ChatViewModel: ✅ pendingInvite updated: true
MainActivity: ✅ pendingInvite set successfully
MainScreen: 🔔 pendingInvite changed: true
MainScreen:    Identity: username
MainScreen:    Token: TOKEN
```

## ❌ Если не работает

### Проблема: Нет логов "Deep link received"
**Решение:** Проверьте AndroidManifest.xml - должен быть intent-filter для HTTPS

### Проблема: Нет "Extracted token"
**Решение:** Проверьте формат ссылки - должна быть `/api/u/TOKEN`

### Проблема: Нет "Processing pending deep link"
**Решение:** 
- Проверьте что пользователь авторизован
- Проверьте логи LaunchedEffect

### Проблема: Нет "Invite preview loaded"
**Решение:**
- Проверьте интернет соединение
- Проверьте что API работает:
```bash
curl https://weeky-six.vercel.app/api/invite/preview/TOKEN
```

### Проблема: Нет "pendingInvite changed"
**Решение:**
- Проверьте что MainScreen отрисован
- Проверьте что collectAsStateWithLifecycle работает

### Проблема: Модалка не появляется
**Решение:**
- Убедитесь что видите лог "pendingInvite changed: true"
- Проверьте что InviteProfileScreen не падает с ошибкой
- Проверьте логи на наличие ошибок Compose

## 🔧 Дополнительная отладка

### Очистка данных приложения
```bash
adb shell pm clear com.bananjemmy
```

### Проверка intent-filter
```bash
adb shell dumpsys package com.bananjemmy | findstr "https"
```

### Принудительная остановка
```bash
adb shell am force-stop com.bananjemmy
```

### Перезапуск с deep link
```bash
adb shell am force-stop com.bananjemmy
adb shell am start -a android.intent.action.VIEW -d "https://weeky-six.vercel.app/api/u/TOKEN"
```
