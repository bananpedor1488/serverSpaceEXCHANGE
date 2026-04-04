# PowerShell скрипт для установки V2ray-Android модуля

Write-Host "🚀 Установка V2ray-Android модуля..." -ForegroundColor Green

# Проверяем что мы в правильной директории
if (-not (Test-Path "settings.gradle.kts")) {
    Write-Host "❌ Ошибка: Запустите скрипт из корня проекта JemmyAndroid" -ForegroundColor Red
    exit 1
}

# Клонируем репозиторий
Write-Host "📥 Клонирование репозитория..." -ForegroundColor Cyan

if (Test-Path "v2ray-module") {
    Write-Host "⚠️  Папка v2ray-module уже существует, удаляем..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "v2ray-module"
}

git clone https://github.com/dev7dev/V2ray-Android.git v2ray-module

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка клонирования репозитория" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Репозиторий склонирован" -ForegroundColor Green

# Обновляем settings.gradle.kts
Write-Host "📝 Обновление settings.gradle.kts..." -ForegroundColor Cyan

$settingsContent = Get-Content "settings.gradle.kts" -Raw

if ($settingsContent -match 'include\(":v2ray"\)') {
    Write-Host "⚠️  Модуль v2ray уже добавлен в settings.gradle.kts" -ForegroundColor Yellow
} else {
    Add-Content "settings.gradle.kts" "`n"
    Add-Content "settings.gradle.kts" 'include(":v2ray")'
    Add-Content "settings.gradle.kts" 'project(":v2ray").projectDir = file("v2ray-module/v2ray")'
    Write-Host "✅ Модуль добавлен в settings.gradle.kts" -ForegroundColor Green
}

# Обновляем app/build.gradle.kts
Write-Host "📝 Обновление app/build.gradle.kts..." -ForegroundColor Cyan

$buildGradleContent = Get-Content "app/build.gradle.kts" -Raw
$buildGradleContent = $buildGradleContent -replace '// implementation\(project\(":v2ray"\)\)', 'implementation(project(":v2ray"))'
Set-Content "app/build.gradle.kts" $buildGradleContent

Write-Host "✅ Зависимость добавлена в app/build.gradle.kts" -ForegroundColor Green

# Обновляем settings.gradle.kts для flatDir
Write-Host "📝 Добавление flatDir репозитория..." -ForegroundColor Cyan

$settingsContent = Get-Content "settings.gradle.kts" -Raw

if ($settingsContent -match 'flatDir') {
    Write-Host "⚠️  flatDir уже добавлен" -ForegroundColor Yellow
} else {
    $flatDirBlock = @"
        flatDir {
            dirs("v2ray-module/v2ray/libs")
        }
"@
    
    $settingsContent = $settingsContent -replace '(repositories \{)', "`$1`n$flatDirBlock"
    Set-Content "settings.gradle.kts" $settingsContent
    
    Write-Host "✅ flatDir репозиторий добавлен" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ Установка завершена!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Следующие шаги:" -ForegroundColor Cyan
Write-Host "1. Откройте проект в Android Studio"
Write-Host "2. Нажмите 'Sync Now' для синхронизации Gradle"
Write-Host "3. Соберите проект: .\gradlew.bat assembleDebug"
Write-Host ""
Write-Host "🔍 Проверка:" -ForegroundColor Cyan
Write-Host "   Запустите приложение и проверьте логи:"
Write-Host "   adb logcat | Select-String V2ray"
Write-Host ""
