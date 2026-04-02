# Vercel Setup для Deep Links

## Что сделано:

✅ **LinkGeneratorView** - ссылка сохраняется на 24 часа
✅ **vercel.json** - настроен для прокси и apple-app-site-association
✅ **apple-app-site-association** - файл для iOS Universal Links

## Структура файлов:

```
serverSpaceEXCHANGE/
├── vercel.json                              ← Конфигурация Vercel
└── .well-known/
    └── apple-app-site-association           ← Файл для iOS
```

## Что нужно сделать:

### 1. Обновить apple-app-site-association

Открой файл: `serverSpaceEXCHANGE/.well-known/apple-app-site-association`

Замени:
- `TEAMID` → твой Team ID из Xcode (например: `ABC123XYZ`)
- `com.yourteam.jemmy` → твой Bundle ID (например: `com.banan.jemmy`)

Должно получиться:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ABC123XYZ.com.banan.jemmy",
        "paths": ["/api/u/*"]
      }
    ]
  }
}
```

### 2. Деплой на Vercel

```bash
cd serverSpaceEXCHANGE
vercel --prod
```

### 3. Проверка

Открой в браузере:
```
https://weeky-six.vercel.app/.well-known/apple-app-site-association
```

Должен вернуться JSON с твоим appID.

### 4. Настройка в Xcode

1. Открой проект Jemmy в Xcode
2. Target → Signing & Capabilities
3. Добавь **Associated Domains**
4. Добавь домен:
   ```
   applinks:weeky-six.vercel.app
   ```

### 5. Тестирование

1. Собери и установи приложение на iPhone
2. Открой приложение → Профиль → Создать ссылку
3. Ссылка сохранится на 24 часа!
4. Отправь ссылку себе в Notes/Messages
5. Нажми на ссылку → должно открыться приложение

## Как работает сохранение ссылки:

1. Создаёшь ссылку → сохраняется в UserDefaults
2. Закрываешь экран → ссылка остаётся
3. Открываешь снова → ссылка загружается
4. Показывается таймер: "Осталось 23ч 45м"
5. Через 24 часа → ссылка автоматически удаляется
6. Можешь создать новую ссылку кнопкой "Создать новую ссылку"

## Структура vercel.json:

```json
{
  "rewrites": [
    {
      "source": "/api/(.*)",
      "destination": "http://178.104.40.37:25593/api/$1"
    }
  ],
  "routes": [
    {
      "src": "/.well-known/apple-app-site-association",
      "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      "dest": "/.well-known/apple-app-site-association"
    }
  ]
}
```

**Что это делает:**
- `rewrites` - проксирует все `/api/*` запросы на твой сервер `178.104.40.37:25593`
- `routes` - отдаёт файл `apple-app-site-association` с правильными заголовками

## Troubleshooting:

### Ссылка не сохраняется:
- Проверь логи в Xcode Console
- Должно быть: "💾 Link saved (expires at ...)"

### Файл не доступен:
```bash
curl https://weeky-six.vercel.app/.well-known/apple-app-site-association
```
Если 404 → проверь, что файл в правильной папке и сделай редеплой

### Ссылка открывается в Safari:
1. Удали приложение
2. Установи заново
3. Перезагрузи iPhone
4. iOS кэширует конфигурацию, нужна переустановка
