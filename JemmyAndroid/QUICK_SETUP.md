# Быстрая установка V2ray VPN

## Автоматическая установка (рекомендуется)

### Windows:
```powershell
cd serverSpaceEXCHANGE\JemmyAndroid
.\setup-v2ray.ps1
```

### Linux/Mac:
```bash
cd serverSpaceEXCHANGE/JemmyAndroid
chmod +x setup-v2ray.sh
./setup-v2ray.sh
```

Скрипт автоматически:
- Клонирует репозиторий V2ray-Android
- Добавит модуль в settings.gradle.kts
- Добавит зависимость в app/build.gradle.kts
- Настроит flatDir репозиторий

---

## Ручная установка (если скрипт не работает)

### Шаг 1: Клонировать репозиторий

```bash
cd serverSpaceEXCHANGE/JemmyAndroid
git clone https://github.com/dev7dev/V2ray-Android.git v2ray-module
```

### Шаг 2: Открыть `settings.gradle.kts` и добавить в конец:

```kotlin
include(":v2ray")
project(":v2ray").projectDir = file("v2ray-module/v2ray")
```

### Шаг 3: В `settings.gradle.kts` найти блок `repositories` и добавить:

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        flatDir {
            dirs("v2ray-module/v2ray/libs")
        }
    }
}
```

### Шаг 4: Открыть `app/build.gradle.kts` и раскомментировать:

Найти строку:
```kotlin
// implementation(project(":v2ray"))
```

Изменить на:
```kotlin
implementation(project(":v2ray"))
```

### Шаг 5: Синхронизировать проект

В Android Studio: File -> Sync Project with Gradle Files

Или через командную строку:
```bash
./gradlew sync
```

### Шаг 6: Собрать проект

```bash
./gradlew assembleDebug
```

---

## Альтернатива: Скачать готовый AAR

Если git не работает или хочешь быстрее:

### 1. Скачай AAR файл:

Перейди на: https://github.com/dev7dev/V2ray-Android/releases/latest

Скачай файл `v2ray-release.aar` или `app-debug.apk` (из него можно извлечь AAR)

### 2. Создай папку libs:

```bash
mkdir -p app/libs
```

### 3. Положи AAR файл в `app/libs/v2ray-release.aar`

### 4. В `app/build.gradle.kts` раскомментируй:

```kotlin
implementation(files("libs/v2ray-release.aar"))
```

### 5. Синхронизируй и собери проект

---

## Проверка установки

После установки запусти приложение и проверь логи:

```bash
adb logcat | grep V2ray
```

Должно быть:
```
V2ray initialized successfully
Version: Xray 1.8.23 (Xray, Penetrates Everything.)
```

---

## Если что-то не работает

### Очистить кэш:
```bash
./gradlew clean
rm -rf .gradle
rm -rf app/build
```

### Пересобрать:
```bash
./gradlew assembleDebug --refresh-dependencies
```

### Проверить что установлено:
```bash
./gradlew dependencies | grep v2ray
```

---

## Нужна помощь?

Смотри подробную инструкцию в `MANUAL_V2RAY_SETUP.md`
