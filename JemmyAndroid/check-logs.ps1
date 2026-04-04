# Скрипт для проверки логов deep link
Write-Host "🔍 Checking deep link logs..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Очистка логов..." -ForegroundColor Yellow
adb logcat -c

Write-Host ""
Write-Host "Ожидание логов (нажмите Ctrl+C для остановки)..." -ForegroundColor Yellow
Write-Host "Теперь откройте ссылку в приложении!" -ForegroundColor Green
Write-Host ""

# Фильтруем только нужные логи
adb logcat | Select-String -Pattern "MainActivity|ChatViewModel|MainScreen|DEEP"
