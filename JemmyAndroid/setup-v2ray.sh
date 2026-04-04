#!/bin/bash

# Скрипт для автоматической установки V2ray-Android модуля

echo "🚀 Установка V2ray-Android модуля..."

# Проверяем что мы в правильной директории
if [ ! -f "settings.gradle.kts" ]; then
    echo "❌ Ошибка: Запустите скрипт из корня проекта JemmyAndroid"
    exit 1
fi

# Способ 1: Клонируем репозиторий
echo "📥 Клонирование репозитория..."
if [ -d "v2ray-module" ]; then
    echo "⚠️  Папка v2ray-module уже существует, удаляем..."
    rm -rf v2ray-module
fi

git clone https://github.com/dev7dev/V2ray-Android.git v2ray-module

if [ $? -ne 0 ]; then
    echo "❌ Ошибка клонирования репозитория"
    exit 1
fi

echo "✅ Репозиторий склонирован"

# Обновляем settings.gradle.kts
echo "📝 Обновление settings.gradle.kts..."

# Проверяем есть ли уже include v2ray
if grep -q 'include(":v2ray")' settings.gradle.kts; then
    echo "⚠️  Модуль v2ray уже добавлен в settings.gradle.kts"
else
    # Добавляем в конец файла
    echo '' >> settings.gradle.kts
    echo 'include(":v2ray")' >> settings.gradle.kts
    echo 'project(":v2ray").projectDir = file("v2ray-module/v2ray")' >> settings.gradle.kts
    echo "✅ Модуль добавлен в settings.gradle.kts"
fi

# Обновляем app/build.gradle.kts
echo "📝 Обновление app/build.gradle.kts..."

# Раскомментируем строку с implementation(project(":v2ray"))
sed -i 's|// implementation(project(":v2ray"))|implementation(project(":v2ray"))|g' app/build.gradle.kts

# Для macOS используем другой синтаксис sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's|// implementation(project(":v2ray"))|implementation(project(":v2ray"))|g' app/build.gradle.kts
fi

echo "✅ Зависимость добавлена в app/build.gradle.kts"

# Обновляем settings.gradle.kts для flatDir
echo "📝 Добавление flatDir репозитория..."

if grep -q 'flatDir' settings.gradle.kts; then
    echo "⚠️  flatDir уже добавлен"
else
    # Находим блок repositories и добавляем flatDir
    sed -i '/repositories {/a\        flatDir {\n            dirs("v2ray-module/v2ray/libs")\n        }' settings.gradle.kts
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/repositories {/a\
        flatDir {\
            dirs("v2ray-module/v2ray/libs")\
        }
' settings.gradle.kts
    fi
    
    echo "✅ flatDir репозиторий добавлен"
fi

echo ""
echo "✅ Установка завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Откройте проект в Android Studio"
echo "2. Нажмите 'Sync Now' для синхронизации Gradle"
echo "3. Соберите проект: ./gradlew assembleDebug"
echo ""
echo "🔍 Проверка:"
echo "   Запустите приложение и проверьте логи:"
echo "   adb logcat | grep V2ray"
echo ""
