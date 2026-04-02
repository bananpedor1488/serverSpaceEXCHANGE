# Deep Links Setup для Jemmy

## Что сделано в коде:

✅ **APIService.swift** - добавлен метод `useInviteLink(token:)`
✅ **JemmyApp.swift** - добавлен обработчик `.onOpenURL`
✅ **InviteProfileView.swift** - создан экран для отображения профиля из ссылки
✅ **apple-app-site-association** - создан файл для Apple
✅ **vercel.json** - настроена конфигурация для Vercel

## Что нужно сделать в Xcode:

### 1. Добавить Associated Domains

1. Открой проект в Xcode
2. Выбери target **Jemmy**
3. Перейди на вкладку **Signing & Capabilities**
4. Нажми **+ Capability**
5. Добавь **Associated Domains**
6. Добавь домен:
   ```
   applinks:weeky-six.vercel.app
   ```

### 2. Узнать Team ID

1. В Xcode, в разделе **Signing & Capabilities**
2. Найди **Team** (например: "John Doe (ABC123XYZ)")
3. Скопируй Team ID (например: `ABC123XYZ`)

### 3. Обновить apple-app-site-association

1. Открой файл `JEMMY-SERVER/.well-known/apple-app-site-association`
2. Замени `TEAMID` на свой Team ID
3. Замени `com.yourteam.jemmy` на свой Bundle ID (например: `com.banan.jemmy`)
4. Должно получиться:
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

### 4. Деплой на Vercel

```bash
cd JEMMY-SERVER
vercel --prod
```

### 5. Проверка

1. Открой в Safari на iPhone: `https://weeky-six.vercel.app/.well-known/apple-app-site-association`
2. Должен вернуться JSON с твоим appID
3. Создай invite ссылку в приложении
4. Отправь её себе в Notes или Messages
5. Нажми на ссылку - должно открыться приложение!

## Как это работает:

1. Пользователь создаёт ссылку: `https://weeky-six.vercel.app/api/u/abc123`
2. Другой пользователь нажимает на ссылку
3. iOS проверяет `apple-app-site-association` на сервере
4. Если приложение установлено → открывает приложение
5. Если нет → открывает в Safari (показывает JSON)
6. Приложение получает URL через `.onOpenURL`
7. Парсит token из URL
8. Вызывает `APIService.useInviteLink(token:)`
9. Показывает `InviteProfileView` с профилем
10. Пользователь нажимает "Начать чат" → создаётся чат

## Troubleshooting

### Ссылка открывается в Safari, а не в приложении:

1. Проверь, что домен добавлен в Associated Domains
2. Проверь, что файл доступен: `https://weeky-six.vercel.app/.well-known/apple-app-site-association`
3. Удали приложение и установи заново (iOS кэширует конфигурацию)
4. Перезагрузи iPhone

### Файл не доступен на Vercel:

1. Проверь, что `vercel.json` загружен
2. Сделай редеплой: `vercel --prod`
3. Проверь логи Vercel

### Приложение не открывается:

1. Проверь Bundle ID в Xcode
2. Проверь Team ID
3. Убедись, что appID в файле правильный: `TEAMID.BUNDLEID`
