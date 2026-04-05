# 🔧 Исправление ошибки SocketIO

## Проблема
```
Undefined symbol: SocketIO.SocketIOClient...
Linker command failed with exit code 1
```

Это означает, что библиотека SocketIO не добавлена в проект.

## ✅ Решение

### Вариант 1: Swift Package Manager (Рекомендуется)

1. Откройте проект в Xcode
2. Выберите проект в навигаторе (синяя иконка Jemmy)
3. Выберите таргет "Jemmy"
4. Перейдите на вкладку "General"
5. Прокрутите вниз до "Frameworks, Libraries, and Embedded Content"
6. Нажмите "+" внизу списка
7. Выберите "Add Package Dependency..."
8. Вставьте URL: `https://github.com/socketio/socket.io-client-swift`
9. Выберите версию: "Up to Next Major Version" → 16.0.0
10. Нажмите "Add Package"
11. Выберите "SocketIO" в списке продуктов
12. Нажмите "Add Package"

### Вариант 2: Через меню File

1. Откройте Xcode
2. File → Add Package Dependencies...
3. Вставьте URL: `https://github.com/socketio/socket.io-client-swift`
4. Dependency Rule: "Up to Next Major Version" → 16.0.0
5. Add to Project: Jemmy
6. Нажмите "Add Package"
7. Выберите "SocketIO"
8. Нажмите "Add Package"

### Вариант 3: Вручную через project.pbxproj (Не рекомендуется)

Если SPM не работает, можно добавить через CocoaPods:

1. Создайте `Podfile` в папке `JemmyIOS/`:
```ruby
platform :ios, '15.0'

target 'Jemmy' do
  use_frameworks!
  
  pod 'Socket.IO-Client-Swift', '~> 16.0.0'
end
```

2. Установите CocoaPods (если не установлен):
```bash
sudo gem install cocoapods
```

3. Установите зависимости:
```bash
cd serverSpaceEXCHANGE/JemmyIOS
pod install
```

4. Откройте `Jemmy.xcworkspace` (НЕ .xcodeproj!)

## 🔍 Проверка

После добавления пакета:

1. Очистите build: Product → Clean Build Folder (Cmd+Shift+K)
2. Пересоберите: Product → Build (Cmd+B)
3. Ошибка должна исчезнуть

## 📦 Альтернатива: Удалить WebSocket функционал

Если SocketIO не нужен прямо сейчас, можно временно закомментировать:

### В `WebSocketManager.swift`:
```swift
// Закомментировать весь файл или заменить на заглушку:
import Foundation

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    @Published var isConnected = false
    
    private init() {}
    
    func connect(identityId: String) {
        print("⚠️ WebSocket disabled - SocketIO not installed")
    }
    
    func disconnect() {}
    func sendMessage(_ message: String, chatId: String) {}
}
```

## 🎯 Рекомендация

Используйте Swift Package Manager (Вариант 1) - это самый простой и надежный способ.

После добавления пакета все должно работать!
