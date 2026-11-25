# TODO: улучшения и исправления Dot Music

> Статус: пункты P0–P3 исходного аудита закрыты и закоммичены в ветке `fix`. Правка пользователя в `lib/core/db/db_helper.dart` (`ORDER BY t.created_at DESC`) сохранена. Коммиты отныне пишутся на английском языке.
>
> Обозначения: **P0** — блокер/краш/нерабочий основной сценарий, **P1** — высокий приоритет, **P2** — средний, **P3** — качество/техдолг, **P4** — отложенные улучшения. Архитектура после исправлений описана в [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## Результаты автоматических проверок

| Проверка | До исправлений | Сейчас |
|---|---|---|
| `flutter analyze --no-pub` | 65 замечаний, 28 предупреждений `notifyListeners()` | ✅ `No issues found!` |
| `flutter test --no-pub` | ❌ пустой `test/widget_test.dart` | ✅ **28 тестов** проходят |
| `dart format --output=none --set-exit-if-changed lib test` | 42 из 46 файлов требуют форматирования | ✅ `0 changed` (проверка добавлена в CI) |
| `flutter pub get` / `flutter gen-l10n` | локализация не подключена | ✅ RU-шаблон + EN, generated-файлы создаются |
| `flutter build apk --flavor dev` (JDK 17) | — | ✅ `app-dev-release.apk` (~43 МБ) собран; Android-сборка добавлена в CI |
| `flutter build apk --release --flavor prod` (JDK 17) | — | ✅ `app-prod-release.apk` (~43 МБ) собран |
| iOS-сборка | — | не проверена: нет macOS/Xcode |

CI: `.github/workflows/ci.yml` — JDK 17 → `pub get` → `analyze` → проверка форматирования → `test` → сборка APK dev.

---

## P0 — стабильность (выполнено)

- [x] **P0-1.** Пустой `test/widget_test.dart` заменён smoke-тестом; всего 28 тестов.
- [x] **P0-2.** Отладочный цикл с `loadedSongs[s]` при <30 треках удалён (`song_list/music_service.dart`).
- [x] **P0-3.** Схема БД v4: `migrateDatabase()` идемпотентна, уникальные индексы и чистка дублей, `resetDatabase()` пересоздаёт таблицы; тесты на in-memory БД.
- [x] **P0-4.** Очередь защищена от пустого списка/невалидного индекса; `PlayerLogic.init()` вызывается с `await` и обработкой ошибки; ошибка показывается в UI.
- [x] **P0-5.** Одна подписка на `durationStream`, no-op listener удалён; `PlayerLogic` — единственный `ChangeNotifier`, владельцем активного плеера является `PlayerStateListener` (dispose старого при регистрации нового), `dispose()` защищён от асинхронных колбэков после закрытия.
- [x] **P0-6.** Автосканирование библиотеки при старте (`main.dart`), кнопка на главной работает как «пересканировать».
- [x] **P0-7.** Поиск трека возвращает `nullable` вместо `SongModel({})`; битые записи пропускаются.
- [x] **P0-8.** Android 13/14+: `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `foregroundServiceType=mediaPlayback`, runtime-запрос разрешения; iOS: Podfile, `UIBackgroundModes=audio`, `NSAppleMusicUsageDescription`.
- [x] **P0-9.** Bundle id заменён на `com.dotmusic.app` (prod) / `com.dotmusic.app.dev` (dev), iOS `com.dotmusic.app`, канал уведомлений `com.dotmusic.app.channel.audio`. Release-подпись подключается при наличии `android/key.properties`, иначе fallback на debug для локальной сборки.

---

## P1 — состояние и данные (выполнено)

- [x] **P1-1.** `setState` после await везде защищён `mounted`; таймер анимации и отложенный callback в `home/ui.dart` отменяются/проверяются.
- [x] **P1-2.** `BuildContext` после async-разрывов: `context.mounted` перед показами/закрытием диалогов, `use_build_context_synchronously` включён в линты.
- [x] **P1-3.** Один канал обновления UI — `ChangeNotifier`; `refreshUI`, `refreshBtn`, `onPlaybackCountLoaded` удалены.
- [x] **P1-4.** `initTracksInBackground()`: `isLoading`-guard, `_scanGeneration`, копия слушателей, сброс старой ошибки/прогресса.
- [x] **P1-5.** `removeTrack()` отдельно обрабатывает избранное/чёрный список/плейлист, обновляет очередь и show error; список треков перезагружается после удаления.
- [x] **P1-6.** `FavoriteService` — синглтон с `ValueNotifier<int> revision`; экраны и плеер подписаны, статус пересчитывается при смене трека.
- [x] **P1-7.** `UNIQUE`-индексы в v4, `INSERT OR IGNORE`, диалог возвращает плейлист целиком и используется его `id`.
- [x] **P1-8.** `playback_count NOT NULL DEFAULT 0`; `StatRepository.registerPlayback()` — транзакция + `COALESCE` + UPSERT, тест на параллельные инкременты.
- [x] **P1-9.** `updateCount(trackId)` обновляет счётчик конкретного трека и только если он всё ещё текущий; инкремент после успешного запуска воспроизведения.
- [x] **P1-10.** Guard'ы границ в плеере, `Future<void>`-методы, `random` использует `playRandomSong()`, логирование списка треков убрано.
- [x] **P1-11.** `PlayerRouteArgs` с безопасным разбором `extra`/query/path, `errorBuilder`; чистый `parse()` покрыт unit-тестами.
- [x] **P1-12.** «Назад» через `context.pop()`/`returnRoute`; мини-плеер не делает force unwrap; циклический импорт устранён через `context.go`.
- [x] **P1-13.** Очередь и индекс хранятся в `MyAudioHandler`, пишутся в `SharedPreferences` и восстанавливаются; `MediaItem.queue`/`queueIndex` заполняются; next/prev из уведомления работают без открытого экрана и после перезапуска.
- [x] **P1-14.** `resetDatabase()` пересоздаёт схему; `deleteDatabaseFile()` закрывает БД; `getTrackInfoById()` возвращает `null`.
- [x] **P1-15.** Разрешения и `querySongs()` запрашиваются один раз, метаданные кэшируются (`core/service.dart`) и передаются в `addSongToDb()`.
- [x] **P1-16.** Отладочная кнопка сброса БД, логирование таблиц/всех треков и избыточные логи убраны или переведены под `kDebugMode`.

---

## P2 — UX и качество (выполнено)

- [x] **P2-1.** Вместо `author` везде читается `artist`.
- [x] **P2-2.** Слайдер показывает preview позиции и делает seek в `onChangeEnd`.
- [x] **P2-3.** Мёртвые кнопки/поля удалены или реализованы; `initialPath` учитывается при выборе трека.
- [x] **P2-4.** `service.dart` разделён на `player_state.dart`, `player_audio_manager.dart`, `player_queue_manager.dart`, `player_favorite_manager.dart`, `player_track_manager.dart` + facade `service.dart`.
- [x] **P2-5.** `TrackTile`, `StatList`, `MiniPlayerScaffold` вынесены и используются в списках/статистике.
- [x] **P2-6.** `getCountTrack()` считает `COUNT(DISTINCT t.id)`.
- [x] **P2-7.** Мёртвые `player_control.dart`, `play_music.dart`, `player_manager.dart` и сгенерированный Android-отчёт удалены.
- [x] **P2-8.** Адаптивность и доступность: `Flexible`/`FittedBox`, `maxLines: 1`, `ellipsis`, `MediaQuery.withClampedTextScaling`, tooltips и `semanticLabel`.
- [x] **P2-9.** Локализация: `app_ru.arb` (шаблон) + `app_en.arb`, `l10n.yaml`, `AppLocalizations` в `MaterialApp.router`, `context.l10n.*` в UI; ошибки вне виджетов получают `AppLocalizations` через состояние/плеер.
- [x] **P2-10.** `ThemeData` использует палитру `design/colors.dart` (primary/secondary/accent/surface/onSurface).
- [x] **P2-11.** Обложка: disposal `image`/`picture`, уникальное имя файла, проверка `File.existsSync()` перед повторным использованием.
- [x] **P2-12.** `onTaskRemoved()` удалён — ongoing-уведомление больше не останавливает музыку.
- [x] **P2-13.** Сортировка списка треков: по популярности (`playback_count`), по алфавиту и по времени добавления **с устройства** (`date_added` MediaStore из `on_audio_query`, fallback — `mtime` файла; не `tracks.created_at`). Метаданные собираются один раз за сессию и сбрасываются после пересканирования; выбор через меню в AppBar.
- [x] **P2-14.** Удаление треков осталось мягким: файл с устройства не удаляется, трек только попадает в чёрный список/убирается из избранного или плейлиста. Проверено интеграционным тестом с реальным временным файлом.

---

## P3 — техдолг (выполнено)

- [x] **P3-1.** Анализатор: `No issues found!`, `PlayerLogic` — Presenter/subclass `ChangeNotifier`, `notifyListeners()` вызывается только внутри него.
- [x] **P3-2.** `Color.withOpacity` заменён на `withValues(alpha: ...)`.
- [x] **P3-3.** `dart format lib test` применён; проверка форматирования добавлена в CI.
- [x] **P3-4.** Включены `unawaited_futures`, `discarded_futures`, `avoid_dynamic_calls`, `use_build_context_synchronously`. `strict-casts` удалён: текущий SDK не поддерживает эту опцию (`unsupported_option_with_legal_values`).
- [x] **P3-5.** `provider` и `just_audio_background` удалены; `shared_preferences` используется для очереди; `flutter_native_splash`/`flutter_launcher_icons` перенесены в `dev_dependencies`.
- [x] **P3-6.** Мёртвые файлы удалены, smoke-тест наполнен.
- [x] **P3-7.** `songsss` → `songs`, `__PlaylistFormOverlayState` → `_PlaylistFormOverlayState`, `ps/pv/ss` переименованы, `montly_stat.dart` → `monthly_stat.dart`, `title: 'Dot Music'`, осмысленное `description` в `pubspec.yaml`.
- [x] **P3-8.** README приведён к фактическому стеку/командам, Markdown исправлен.
- [x] **P3-9.** Сгенерированный отчёт удалён; ключ и `key.properties` остаются в `.gitignore`.

---

## P4 — отложено (не делать в этой итерации)

- [ ] **P4-1.** Улучшение интерфейса и цветовой палитры: пересмотреть `design/colors.dart`, контрастность, типографику и состояния экранов.
- [ ] **P4-2.** Отображение обложек треков, если они есть в метаданных/на устройстве: использовать `artwork` из `on_audio_query` с кэшированием и graceful fallback на градиент.
- [ ] **P4-3.** Управление очередью воспроизведения: менять порядок треков (drag-and-drop), удалять треки из очереди, дублировать их и подобные операции; синхронизация изменений с медиа-сессией и `SharedPreferences`.

---

## Тесты: что покрыто

| Файл | Что проверяет |
|---|---|
| `test/widget_test.dart` | smoke-рендер MaterialApp + сборка `DotMusic` (регресс белого экрана из-за `context.l10n` до `MaterialApp`) |
| `test/queue_test.dart` | `makeQueue`/`shuffleQueue`: пустой список, границы индекса, неизменяемость входа |
| `test/db_migration_test.dart` | схема v4, v1→v4, идемпотентность, уникальные индексы, транзакционный `registerPlayback` |
| `test/router_args_test.dart` | разбор аргументов плеера без `extra`, неверные типы, `returnRoute` |
| `test/loading_state_test.dart` | рассылка слушателям переживает отписку во время notify |
| `test/player_logic_test.dart` | пустая очередь, repeat/shuffle, `syncQueue` и media-очередь, dispose снимает колбэки/подписки, внешняя смена индекса |
| `test/player_holder_test.dart` | `PlayerStateListener` владеет активным плеером и dispose'ит предыдущий |
| `test/track_loader_test.dart` | в БД добавляются только отсутствующие треки, прогресс полный, ошибка одного трека не прерывает сканирование |
| `test/track_sort_test.dart` | популярность, алфавит и дата добавления из переданных метаданных устройства |
| `test/soft_delete_test.dart` | после блокировки трека файл остаётся на устройстве, трек возвращается после разблокировки |
| `test/support/fake_audio_controller.dart` | заглушка `AudioController` для unit-тестов без нативных плагинов |

Отдельно введена абстракция `AudioController` (`lib/features/player/audio_controller.dart`): `MyAudioHandler` её реализует, тесты подменяют заглушкой.

---

## Известные ограничения окружения

- По умолчанию в системе Java 27, с ней Gradle 9 падает на `jlink`. Для сборки нужно явно задать JDK 17: `export JAVA_HOME=/usr/lib/jvm/java-17-openjdk`. В CI JDK 17 подключается через `actions/setup-java`; лимиты JVM Gradle/Kotlin снижены в `android/gradle.properties`.
- iOS-сборка не проверялась (нет macOS/Xcode); конфиги (`Podfile`, `Info.plist`, bundle id) приведены в рабочее состояние.
- `flutter test` печатает предупреждение логгера `Invalid initial queue index -1` из теста на невалидном индексе — это ожидаемое поведение `QueueService`, тесты зелёные.
