# Jemmy - Анонимный мессенджер

iOS-native мессенджер с Ephemeral Identity

## Быстрый старт

```bash
npm install
npm start
```

Выбери iOS симулятор или физическое устройство.

## Фичи

🫥 **Ephemeral Identity** - личность исчезает каждые 24 часа (опционально)
💬 **Real-time чаты** - WebSocket с typing indicator
🎨 **iOS-native UX** - системная тема, haptics, анимации
🔐 **E2E encryption** - ключи генерируются на клиенте
🎭 **Уникальный онбординг** - "Ты никто. Но ты можешь стать кем угодно."

## Структура

```
app/
├── (onboarding)/     # Онбординг с анимацией
├── (tabs)/           # Главные экраны
│   ├── index.tsx     # Список чатов
│   └── profile.tsx   # Профиль + Ephemeral toggle
└── chat/[id].tsx     # Экран чата

store/
└── auth.store.ts     # Zustand state

services/
├── api.ts            # REST API
└── socket.ts         # WebSocket client

components/
└── IdentityUpdateModal.tsx  # Модалка "Ты стал другим"
```

## Backend

Запусти сервер:
```bash
cd ../JEMMY-SERVER
npm install
npm run start:dev
```

Сервер будет на `http://localhost:3000`

## Технологии

- React Native + Expo Router
- TypeScript
- Zustand (state management)
- Socket.io-client (WebSocket)
- react-native-reanimated (анимации)
- expo-haptics (тактильная обратная связь)
