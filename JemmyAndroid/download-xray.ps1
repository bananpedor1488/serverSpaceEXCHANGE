# PowerShell скрипт для скачивания AndroidLibXrayLite

Write-Host "📥 Скачивание AndroidLibXrayLite..." -ForegroundColor Green

# Создаем папку libs если её нет
if (-not (Test-Path "app/libs")) {
    New-Item -ItemType Directory -Path "app/libs" | Out-Null
    Write-Host "✅ Создана папка app/libs" -ForegroundColor Green
}

# URL для скачивания
$url = "https://github.com/2dust/AndroidLibXrayLite/releases/download/v1.8.13/libv2ray.aar"
$output = "app/libs/libv2ray.aar"

Write-Host "📡 Скачивание с GitHub..." -ForegroundColor Cyan
Write-Host "URL: $url" -ForegroundColor Gray

try {
    # Скачиваем файл
    Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
    
    if (Test-Path $output) {
        $size = (Get-Item $output).Length / 1MB
        Write-Host "✅ Файл скачан: $output ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
        
        # Раскомментируем строку в build.gradle.kts
        Write-Host "📝 Обновление app/build.gradle.kts..." -ForegroundColor Cyan
        
        $buildGradleContent = Get-Content "app/build.gradle.kts" -Raw
        $buildGradleContent = $buildGradleContent -replace '// implementation\(files\("libs/libv2ray.aar"\)\)', 'implementation(files("libs/libv2ray.aar"))'
        Set-Content "app/build.gradle.kts" $buildGradleContent
        
        Write-Host "✅ Зависимость добавлена в build.gradle.kts" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎉 Установка завершена!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Следующие шаги:" -ForegroundColor Cyan
        Write-Host "1. Откройте проект в Android Studio"
        Write-Host "2. Нажмите 'Sync Now'"
        Write-Host "3. Соберите проект: .\gradlew.bat assembleDebug"
        Write-Host ""
    } else {
        Write-Host "❌ Ошибка: Файл не был скачан" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Ошибка скачивания: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Попробуйте скачать вручную:" -ForegroundColor Yellow
    Write-Host "1. Откройте в браузере: $url"
    Write-Host "2. Сохраните как: $output"
    Write-Host "3. Раскомментируйте строку в app/build.gradle.kts:"
    Write-Host "   implementation(files(`"libs/libv2ray.aar`"))"
    exit 1
}
