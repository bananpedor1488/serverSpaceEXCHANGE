#!/bin/bash

# Скрипт для скачивания AndroidLibXrayLite

echo "📥 Скачивание AndroidLibXrayLite..."

# Создаем папку libs если её нет
if [ ! -d "app/libs" ]; then
    mkdir -p app/libs
    echo "✅ Создана папка app/libs"
fi

# URL для скачивания
URL="https://github.com/2dust/AndroidLibXrayLite/releases/download/v1.8.13/libv2ray.aar"
OUTPUT="app/libs/libv2ray.aar"

echo "📡 Скачивание с GitHub..."
echo "URL: $URL"

# Скачиваем файл
if command -v wget &> /dev/null; then
    wget -O "$OUTPUT" "$URL"
elif command -v curl &> /dev/null; then
    curl -L -o "$OUTPUT" "$URL"
else
    echo "❌ Ошибка: wget или curl не найдены"
    echo "Установите wget или curl и попробуйте снова"
    exit 1
fi

if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "✅ Файл скачан: $OUTPUT ($SIZE)"
    
    # Раскомментируем строку в build.gradle.kts
    echo "📝 Обновление app/build.gradle.kts..."
    
    sed -i 's|// implementation(files("libs/libv2ray.aar"))|implementation(files("libs/libv2ray.aar"))|g' app/build.gradle.kts
    
    # Для macOS используем другой синтаксис sed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's|// implementation(files("libs/libv2ray.aar"))|implementation(files("libs/libv2ray.aar"))|g' app/build.gradle.kts
    fi
    
    echo "✅ Зависимость добавлена в build.gradle.kts"
    echo ""
    echo "🎉 Установка завершена!"
    echo ""
    echo "📋 Следующие шаги:"
    echo "1. Откройте проект в Android Studio"
    echo "2. Нажмите 'Sync Now'"
    echo "3. Соберите проект: ./gradlew assembleDebug"
    echo ""
else
    echo "❌ Ошибка скачивания"
    echo ""
    echo "💡 Попробуйте скачать вручную:"
    echo "1. Откройте в браузере: $URL"
    echo "2. Сохраните как: $OUTPUT"
    echo "3. Раскомментируйте строку в app/build.gradle.kts:"
    echo '   implementation(files("libs/libv2ray.aar"))'
    exit 1
fi
