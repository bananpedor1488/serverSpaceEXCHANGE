# Ручная установка V2ray-Android модуля

## Способ 1: Импорт модуля из GitHub

### Шаг 1: Скачать репозиторий

```bash
cd serverSpaceEXCHANGE/JemmyAndroid
git clone https://github.com/dev7dev/V2ray-Android.git v2ray-module
```

### Шаг 2: Добавить модуль в settings.gradle.kts

Открой `settings.gradle.kts` и добавь:

```kotlin
include(":app")
include(":v2ray")
project(":v2ray").projectDir = file("v2ray-module/v2ray")
```

### Шаг 3: Добавить зависимость в app/build.gradle.kts

```kotlin
dependencies {
    // ... другие зависимости
    
    implementation(project(":v2ray"))
}
```

### Шаг 4: Добавить репозиторий для нативных библиотек

В `settings.gradle.kts` добавь в блок repositories:

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

### Шаг 5: Синхронизировать проект

```bash
./gradlew sync
```

---

## Способ 2: Скачать готовый AAR файл

### Шаг 1: Создать папку для библиотек

```bash
mkdir -p app/libs
```

### Шаг 2: Скачать AAR

Скачай последний релиз с GitHub:
https://github.com/dev7dev/V2ray-Android/releases/latest

Или используй wget:

```bash
cd app/libs
wget https://github.com/dev7dev/V2ray-Android/releases/download/v8.1823/v2ray-release.aar
```

### Шаг 3: Добавить в app/build.gradle.kts

```kotlin
android {
    // ...
}

dependencies {
    // ... другие зависимости
    
    // V2ray AAR
    implementation(files("libs/v2ray-release.aar"))
}
```

### Шаг 4: Добавить flatDir репозиторий

В `app/build.gradle.kts` или `settings.gradle.kts`:

```kotlin
repositories {
    flatDir {
        dirs("libs")
    }
}
```

---

## Способ 3: Использовать локальный Maven репозиторий

### Шаг 1: Клонировать репозиторий

```bash
git clone https://github.com/dev7dev/V2ray-Android.git
cd V2ray-Android
```

### Шаг 2: Опубликовать в локальный Maven

```bash
./gradlew publishToMavenLocal
```

### Шаг 3: Добавить mavenLocal в репозитории

В `settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        mavenLocal()
        google()
        mavenCentral()
    }
}
```

### Шаг 4: Добавить зависимость

В `app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.dev7:v2ray:8.1823")
}
```

---

## Способ 4: Копировать исходники напрямую

### Шаг 1: Скачать репозиторий

```bash
git clone https://github.com/dev7dev/V2ray-Android.git
```

### Шаг 2: Скопировать файлы

```bash
# Копируем Java/Kotlin файлы
cp -r V2ray-Android/v2ray/src/main/java/* app/src/main/java/

# Копируем нативные библиотеки
cp -r V2ray-Android/v2ray/libs/* app/libs/

# Копируем ресурсы
cp -r V2ray-Android/v2ray/src/main/res/* app/src/main/res/
```

### Шаг 3: Обновить пакеты

Измени package в скопированных файлах с `com.dev7.lib.v2ray` на `com.bananjemmy.v2ray`

### Шаг 4: Обновить V2rayManager.kt

```kotlin
import com.bananjemmy.v2ray.V2rayController
import com.bananjemmy.v2ray.utils.V2rayConstants
```

---

## Проверка установки

После любого способа, проверь что все работает:

```kotlin
// В MainActivity onCreate
try {
    V2rayManager.initialize(this)
    val version = V2rayManager.getCoreVersion()
    Log.d("V2ray", "Version: $version")
} catch (e: Exception) {
    Log.e("V2ray", "Failed to initialize", e)
}
```

Если видишь версию в логах - все работает!

---

## Troubleshooting

### Ошибка: "Native library not found"

Убедись что:
1. `android:extractNativeLibs="true"` в AndroidManifest.xml
2. Нативные библиотеки (.so файлы) находятся в `app/libs/` или `v2ray/libs/`
3. В build.gradle есть:
```kotlin
android {
    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("libs")
        }
    }
}
```

### Ошибка: "Class not found"

Проверь что:
1. Модуль правильно подключен в settings.gradle.kts
2. Зависимость добавлена в app/build.gradle.kts
3. Проект синхронизирован (Sync Now)

### Ошибка при сборке

Попробуй:
```bash
./gradlew clean
./gradlew build --refresh-dependencies
```

---

## Рекомендуемый способ

Для твоего случая рекомендую **Способ 1** (импорт модуля):
- Легко обновлять (git pull)
- Не нужно копировать файлы
- Исходники доступны для отладки
- Стандартный подход Android

Если не работает - используй **Способ 2** (AAR файл):
- Самый простой
- Не требует git
- Один файл
- Быстрая установка
