# Dot Music

Офлайн-плеер музыки на Flutter: библиотека треков в SQLite, воспроизведение через `just_audio`, фоновое воспроизведение и медиа-уведомления через `audio_service`.

Поддерживаются Android и iOS. Каталоги `linux/`, `macos/` и `windows/` есть, но десктопная поддержка не реализована.

## Разработка

Нужны Flutter stable (SDK Dart ^3.8.1) и **JDK 17** для Android-сборки. Если в системе по умолчанию стоит другая версия Java, укажите 17 явно:

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk   # путь к вашему JDK 17
flutter pub get
flutter run --flavor dev        # Android
flutter analyze --no-pub
flutter test --no-pub
```

Флейворы `dev` и `prod` заданы в `android/app/build.gradle.kts`: разные `applicationId` и имена приложения. Для iOS отдельных флейворов нет — используется стандартный scheme `Runner`.

## Сборка

Android:

```bash
flutter build apk --release --flavor prod
# build/app/outputs/flutter-apk/app-prod-release.apk
```

Пример быстрой проверки dev-сборки: `flutter build apk --debug --flavor dev`. Gradle и Kotlin работают с JDK 17 (параметры JVM заданы в `android/gradle.properties`).

Для release-подписи нужен `android/key.properties` с полями `storeFile`, `storePassword`, `keyAlias`, `keyPassword` и сам keystore. Оба файла не хранятся в git. Без `key.properties` релиз подписывается debug-ключом — только для локальной проверки, не для публикации.

iOS (только macOS):

```bash
cd ios
pod install
cd ..
flutter build ipa --release
```

`ios/Podfile` есть в репозитории. Для публикации откройте `ios/Runner.xcworkspace` в Xcode и выполните Archive.

Настройки splash-экрана и иконок лежат в `pubspec.yaml`; генераторы вынесены в `dev_dependencies`:

```bash
dart run flutter_native_splash:create
dart run flutter_launcher_icons:main
```

## Стек

| Компонент | Пакет / решение |
|---|---|
| Воспроизведение | `just_audio` + `audio_service` |
| Локальная БД | `sqflite` |
| Файлы и пути | `path_provider` + `path` |
| Разрешения | `permission_handler` |
| Навигация | `go_router` |
| Логирование | `logger` |
| Локальные настройки | `shared_preferences` |
| Состояние UI | `setState` + синглтоны сервисов (`provider` не используется) |

Текущее состояние и известные проблемы описаны в [ARCHITECTURE.md](ARCHITECTURE.md) и [TODO.md](TODO.md).

## Лицензия

MIT — см. [LICENSE](LICENSE).
