# Jemmy - Анонимный мессенджер

iOS-native мессенджер с Ephemeral Identity

## Установка

```bash
npm install
```

## Запуск

```bash
npm start
```

## Фичи

- 🫥 Ephemeral Identity (опционально)
- 💬 Real-time чаты через WebSocket
- 🎨 iOS-native UX с системной темой
- 🔐 End-to-end encryption
- ⚡️ Haptic feedback
- 🎭 Уникальный онбординг

## Структура

- `app/(onboarding)` - онбординг экран
- `app/(tabs)` - главные экраны (чаты, профиль)
- `app/chat/[id]` - экран чата
- `store/` - Zustand state management
- `services/` - API и WebSocket
- `components/` - переиспользуемые компоненты

## Backend

Запусти сервер из папки JEMMY-SERVER:
```bash
cd ../JEMMY-SERVER
npm install
npm run start:dev
```
