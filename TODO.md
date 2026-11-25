# TODO: улучшения и исправления Dot Music

> Аудит проведён по состоянию репозитория на коммите `173800a`. После аудита выполнена первая итерация исправлений (P0): код приложения и платформенные конфиги изменены, добавлены тесты. Незакоммиченная правка пользователя в `lib/core/db/db_helper.dart` (сортировка `created_at DESC`) сохранена. Архитектура описана в [`ARCHITECTURE.md`](ARCHITECTURE.md).
>
> Обозначения: **P0** — блокер/краш/нерабочий основной сценарий, **P1** — высокий приоритет, **P2** — средний, **P3** — качество/техдолг. Ссылки вида `lib/...:12-20` указывают на строки файлов.

---

## Результаты автоматических проверок

| Проверка | Было (аудит) | Стало (после исправлений P0) |
|---|---|---|
| `flutter analyze --no-pub` | 65 замечаний | 0 ошибок; 62 замечания (28 предупреждений `notifyListeners()` + info) |
| `flutter test --no-pub` | ❌ пустой `test/widget_test.dart` | ✅ 9 тестов проходят |
| `dart format --output=none --set-exit-if-changed lib test` | 42 из 46 файлов | 43 из 48 файлов (форматирование — отдельный пункт P3) |
| `ios/Podfile` | отсутствует | восстановлен из шаблона Flutter |
| `flutter build apk --flavor dev` | — | ❌ падает из-за несовместимости Gradle/Java 27 в этом окружении (`jlink`), не связано с кодом |

## Что уже исправлено (итерация P0)

- [x] Автосканирование библиотеки при старте (`lib/main.dart`), сброс старой ошибки загрузки.
- [x] Отладочный цикл с `loadedSongs[s]` при <30 треках удалён (`song_list/music_service.dart`).
- [x] Версия БД 3 + идемпотентные миграции `migrateDatabase()` (`core/db/db.dart`), тесты на in-memory БД (`test/db_migration_test.dart`).
- [x] Защита очереди от пустого/невалидного индекса и `await init()` с обработкой ошибки (`queue/queue.dart`, `pages/player/service.dart`, `play_track.dart`).
- [x] Одна подписка на `durationStream` вместо подписки на каждый трек; удалён no-op listener; старый `PlayerLogic` dispose'ится при регистрации нового (`audio_handler.dart`, `player_holder.dart`, `service.dart`).
- [x] `SongModel({})` заменён на поиск с возвратом `null` (`core/service.dart`).
- [x] Android: `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `foregroundServiceType=mediaPlayback`,runtime-запрос разрешения; iOS: Podfile + `UIBackgroundModes`/`NSAppleMusicUsageDescription`.
- [x] Release-подпись подключена при наличии `android/key.properties`; `android:label` берётся из flavor-ресурса.
- [ ] Bundle id `com.example.dot_music*` **пока не менялся** — смена ломает данные существующих пользователей; нужно отдельное решение (см. P0-9).

---

## P0 — исправить в первую очередь

- [x] **P0-1. `flutter test` красный из-за пустого теста.** `test/widget_test.dart` — 0 байт; тестовая обвязка требует функции `main()`. Добавить минимальный smoke-тест (или удалить файл и написать реальные тесты), иначе CI/локальная проверка всегда падает. См. также раздел «Тесты» ниже.

- [x] **P0-2. Падение загрузки списка при менее чем 30 треках.** `lib/features/pages/song_list/music_service.dart:30-32`:
  ```dart
  for (int s = 0; s < 30; s++) {
    logger.i('DB loaded title: ${loadedSongs[s]["title"]}');
  }
  ```
  При 0–29 треках `RangeError` → `rethrow` (`:36-38`) → экран показывает «Треки не найдены», хотя данные есть. Удалить отладочный цикл или заменить на `loadedSongs.take(30)`.

- [x] **P0-3. Версия схемы БД не совпадает с миграциями.** `lib/core/db/db.dart:17` — `databaseVersion = 1`, но `_onUpgrade` содержит ветки `<2` и `<3` (`:45-52`), создающие/изменяющие `listening_stat.year`. На установленной БД v1 миграции никогда не запустятся; при наивном повышении версии до 3 `ALTER TABLE ... ADD COLUMN year` упадёт с `duplicate column`, потому что `Schema.createStatTable` уже создаёт `year` (`schema.dart:32-42`). Поднять версию, написать корректную историю миграций, покрыть тестами 1→2→3 и reset.

- [x] **P0-4. Крах плеера на пустой/устаревшей очереди.** `lib/features/queue/queue.dart:14-18` (`sublist`, `removeAt` без проверки границ) и `lib/features/pages/player/service.dart:49-56` (сразу `state.songs[0]`) при пустом плейлисте/избранном или невалидном `initialIndex` дают `RangeError`. `play_track.dart:57` вызывает `_logic.init()` без `await` → unhandled exception, UI остаётся в «играет». Проверять `isNotEmpty` и границы индекса, выставлять `state.error`, делать `await` с обработкой ошибки.

- [x] **P0-5. Утечки слушателей/подписок плеера.** `lib/features/player/audio_handler.dart:37` добавляет пустой `callBackWidget` (`:83`) в singleton при каждом `playFromFile`; `:57-64` создаёт новую подписку `durationStream` при каждом треке. `PlayerLogic.dispose()` (`pages/player/service.dart:99-103`) нигде не вызывается; `play_track.dart:206-210` снимает только локальный listener. `PlayerStateListener` (`player_holder.dart:8-9`) удерживает ссылки на старые `PlayerLogic` вместе с колбэками и `BuildContext`. Выносить подписку на `durationStream` в конструктор один раз, удалить no-op listener, вызывать `dispose()`/отписку при закрытии страницы-владельца; владение лучше передать в `ChangeNotifierProvider` выше по дереву.

- [x] **P0-6. Первый запуск не загружает библиотеку.** `lib/main.dart:17` — `// initTracksInBackground();`; сканирование только по кнопке (`home.dart:76-80`). Включить автозагрузку после инициализации БД/аудиосервиса, кнопку оставить как «пересканировать».

- [x] **P0-7. `SongModel({})` бросает TypeError вместо «не найдено».** `lib/core/service.dart:15-21`: `orElse: () => SongModel({})`, затем `song.data.isEmpty`. Геттер `data` плагина читает `_info["_data"]` как `String` → `null` → TypeError. Возвращать `null` из поиска (`firstWhere` с флагом или цикл) и корректно обрабатывать отсутствие трека в `crud.dart:142-154`.

- [x] **P0-8. Фоновая работа на Android 14+ и iOS.** `android/app/src/main/AndroidManifest.xml:22,48-54`: нет `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS` и `android:foregroundServiceType="mediaPlayback"` (сравнить с example `audio_service`). На targetSdk 34+ возможен `SecurityException`, на Android 13+ не появится уведомление. На iOS: отсутствует `ios/Podfile` и `UIBackgroundModes = audio` в `ios/Runner/Info.plist`. Добавить разрешения/тип сервиса, запросить `POST_NOTIFICATIONS` через уже подключённый `permission_handler`, восстановить Podfile и поставить background mode.

- [ ] **P0-9 (частично). Bundle id и подпись release.** ✅ Подпись release подключена при наличии `android/key.properties` (`android/app/build.gradle.kts:71-77`), `android:label` теперь `@string/app_name` с flavor-переопределением; ⛔ осталось заменить `com.example.dot_music*` (`build.gradle.kts:55,60`, `AndroidManifest.xml:3`, канал уведомлений в `lib/features/player/audio.dart:19`) на реальный bundle id. **Не делаю автоматически**: смена applicationId приведёт к потере данных текущих пользователей при обновлении. Нужно решение: оставить как есть до релиза или сделать миграцию БД/настроек.

---

## P1 — высокий приоритет

### Состояние и жизненный цикл UI

- [ ] **P1-1. `setState` после `await` без проверки `mounted`** — массово:
  - `lib/features/pages/home/home.dart:47-55` (создание плейлиста);
  - `lib/features/pages/song_list/music_list_page.dart:45-63,97-104` (переименование/загрузка, ещё и без `await` на записи);
  - `lib/features/pages/playlist/playlist.dart:28-37,53-73`;
  - `lib/features/pages/playlist/playlist_list.dart:21-29,37-43`;
  - `lib/features/pages/favorite_songs/favorite_songs_page.dart:25-39,95-99`;
  - `lib/features/pages/home/ui.dart:58-81` (таймер анимации).
  
  Единый паттерн: `final r = await ...; if (!mounted) return; setState(...)`. Отложенные `Future.delayed` в `home/ui.dart:66` тоже отменять/проверять `mounted`.

- [ ] **P1-2. `BuildContext` после async-разрывов.** `song_list/music_list_page.dart:136-142` (`context` в `PlaylistSelectionDialog.show` после `await getPlaylists()`), `track_service/edit_info.dart:56-63` (`Navigator.pop(dialogContext, ...)` после записи в БД), `playlist/playlist.dart:62-73`. Добавить `context.mounted` перед показом/закрытием диалогов. Анализатор уже ругается на первые два (`use_build_context_synchronously`).

- [ ] **P1-3. Три канала обновления UI плеера.** `PlayerLogic` одновременно дёргает `notifyListeners()`, `refreshUI()`/`refreshBtn()` и `PlayerStateListener._notifyListeners()` (`service.dart:142-152,198-199`, `player_holder.dart:35-43`). Оставить один источник правды (ChangeNotifier + Provider) и убрать дублирующие колбэки/пустой `onPlaybackCountLoaded` (`service.dart:20`, `play_track.dart:33`).

- [ ] **P1-4. `TrackLoadingState` — липкая ошибка и гонки.** `lib/features/track_service/load_tracks.dart:5-61`: `error` выставляется при отказе в разрешении (`music_library.dart:102-115`) и никогда не сбрасывается; повторная успешная загрузка всё равно показывает ошибку (`load_tracks.dart:50-53`). `initTracksInBackground()` вызывается fire-and-forget (`home.dart:78,202`), параллельные сканирования не блокируются; `loadedTracks` не обнуляется; `notify()` (`:15-19`) итерирует список слушателей без копии → concurrent modification при отписке. Сброс ошибки в начале запуска, `isLoading`-guard/генерация токена, копия списка слушателей.

### Избранное, удаление и целостность данных

- [ ] **P1-5. `removeTrack()` ломает избранное и не обновляет очередь.** `pages/player/service.dart:456-465`: при `playlist == -1` вызывается `PlaylistService.deleteFromPlaylist(-1, path)` (плейлист не найден), `state.songs`/`currentSongIndex` не обновляются, нет `try/catch` и `notifyListeners()`. Отдельная ветка для `-1` → `FavoriteService.deleteFromFav`, обновление списка и переход на валидный трек. Аналогично `music_list_page.dart:154-160` — после добавления в чёрный список список не перезагружается.

- [ ] **P1-6. Рассинхронизация избранного между экранами.** `pages/player/service.dart:225-254` (`playSongByIndex`, `playRandomSong`) не обновляют `isFavorite`; `toggleFavorite()` (`:372-392`) не уведомляет `FavoriteSongsPage`; удаление на `favorite_songs_page.dart:95-99` не обновляет плеер. Ввести единый `FavoritesRepository` с уведомлением слушателей и перевычислять статус при каждом переходе.

- [ ] **P1-7. Дубли в БД.** `schema.dart:13-19,45-62`: нет `UNIQUE(name)` у плейлистов, `UNIQUE(track_id)` у `favorite_songs`/`black_list`, `UNIQUE(path)` у `tracks`. `fav_service.dart:13-16` и `block_service.dart:11-14` — обычный `INSERT`: двойной тап создаёт дубли. `playlist_dialog.dart:50` возвращает имя плейлиста, а `db_helper.dart:9-24` берёт `limit: 1` → трек попадает в первый попавшийся плейлист с таким именем. Передавать `id`, добавить ограничения + `INSERT OR IGNORE`, миграцию для существующих дублей.

- [ ] **P1-8. Счётчик прослушиваний: nullable и неатомарный.** `schema.dart:8` — `playback_count INTEGER` без `NOT NULL DEFAULT 0`, а `stat_crud.dart:19` делает `as int` → TypeError на null. `stat_crud.dart:58-68` — read-modify-write без транзакции/upsert: параллельные `next` + `onTrackComplete` теряют инкременты и создают дубли строк в `listening_stat`. `UPDATE ... COALESCE + 1`, `INSERT ... ON CONFLICT ... DO UPDATE`, `UNIQUE(track_id, month, year)`, транзакции.

- [ ] **P1-9. `updateCount()` игнорирует свой аргумент.** `pages/player/service.dart:441-453`: после `registerPlayback(trackId)` значение читается из `state.songs[currentSongIndex]`, который мог измениться за время `await`. Использовать переданный `trackId` и обновлять UI только если трек всё ещё текущий. Счётчик инкрементируется в `init()` (`:56`) до фактического старта трека — переносить после успешного `playFromFile`.

- [ ] **P1-10. Проверки границ в плеере.** `service.dart:180-182` логирует `songs[currentSongIndex]` до проверки `isEmpty`; `:365-370` то же в `updateFavoriteStatus`; `playSongByIndex()` (`:225-233`) не проверяет индекс; `RepeatMode.random` (`:284-286`) вызывает обычный `playNextSong()` вместо `playRandomSong()`; `_handleTrackComplete()` (`:271-288`) — `void async` с логированием всех треков. Переставить guard'ы, сделать методы `Future<void>`, уточнить семантику shuffle/repeat-random.

### Навигация и.platform

- [ ] **P1-11. Небезопасные `extra` в роутере.** `core/router.dart:29,40-45,60,67` — `as int` / `as Map<String,dynamic>` / `as bool` без проверок; нет `errorBuilder`. Прямой заход на `/player`, `/playlists`, `/statistic/month` (deep link, тап по уведомлению, hot reload) → CastError/blank screen. Валидировать с fallback, вынести аргументы в `PlayerRouteArgs`, использовать `pathParameters`, добавить `errorBuilder`.

- [ ] **P1-12. «Назад» в плеере и мёртвая ветка мини-плеера.** `play_track.dart:113-120` выбирает маршрут по `playlist` (0 → `/list`, -1 → `/fav`, иначе `/playlists`), поэтому из мини-плеера на главной попадаем не туда, откуда пришли. `mini_player.dart:30-59` — `if`/`else` идентичны, `currentPath!` может упасть. Использовать `context.pop()`/явный `returnRoute`, убрать дублирование и force unwrap. Циклический импорт `playlist_list.dart:1` ↔ `core/router.dart:4` (глобальный `router.go("/")`) заменить на `context.go`.

- [ ] **P1-13. Кнопки уведомления зависят от открытого экрана.** `audio_handler.dart:147-154` → `PlayerStateListener.playNext/Previous()` → `_playerLogic` есть только после `PlayerPage.initState` (`player_holder.dart:63-73`). До открытия плеера next/prev в медиа-уведомлении не работают; после смерти процесса очередь не восстанавливается (`shared_preferences` не используется). Хранить очередь/индекс в `AudioHandler`, заполнять `MediaItem.queue`/`queueIndex` (сейчас всегда `0`, `audio_handler.dart:180`), восстанавливать состояние при старте. `artworkPath`/`artworkUri` в `playFromFile` (`:33-36`) игнорируются, `updateMetadata()`/`customAction()` — no-op.

- [ ] **P1-14. БД reset/delete оставляют нерабочую БД.** `core/db/db.dart:65-82` дропает таблицы, но не пересоздаёт их (лог при этом говорит «recreated»); `:90-97` удаляет файл, не закрыв статический `_db`. Пересоздавать схему после drop и вызывать `close()` перед удалением файла. `DbHelper.getTrackInfoById()` (`db_helper.dart:44-60`) делает `track.first` без проверки `isEmpty` — использовать nullable возврат и пропускать битые записи.

- [ ] **P1-15. O(N²) запросов при сканировании.** `core/service.dart:5-21` при каждом вызове делает `permissionsRequest()` + `querySongs()`; вызывается в цикле из `music_library.dart:74-87` через `crud.dart:142-151`. Один раз запросить разрешения и один раз построить `Map<path, SongModel>`, затем передавать метаданные в `SongService.addSongToDb`. Разделить слой БД и platform-слой. `SongService` (`crud.dart:36-41`) любую ошибку поиска трактует как «трека нет» и добавляет дубль — сузитьcatch до конкретного случая «не найдено».

- [ ] **P1-16. Отладочные элементы в проде.** `home.dart:75` и `home/ui.dart:252-264` — кнопка `onDebug`, скидывающая все таблицы в лог (`db.dart:60`); `service.dart:272-274` логирует весь список треков при каждом завершении; `db_helper.dart:81`, `favorite_songs_page.dart:36`, `music_library.dart:28-61` — избыточное логирование с эмодзи. Убрать/перевести под `kDebugMode`.

---

## P2 — средний приоритет

- [ ] **P2-1. Неверное поле исполнителя.** `pages/player/ui_widgets.dart:111` читает `song['author']`, но БД отдаёт `artist` (`schema.dart:6`, `db_helper.dart:56`, `crud.dart:82`) → всегда «Неизвестный исполнитель». Исправить ключ.
- [ ] **P2-2. Неперетаскиваемый слайдер.** `pages/player/ui.dart:65-70` — `onChanged: (v) {}`, seek только в `onChangeEnd`. Добавить локальный preview позиции или сразу `onChanged: onSeek`.
- [ ] **P2-3. Мёртвые кнопки/поля.** `play_track.dart:129-133` → `_openPlayerSettings() {}` (`:224`); `ui_widgets.dart:122-127` — `// TODO: show menu`; `ui.dart:14,20` — `isLoading` не используется; `service.dart:23,36` — `initialPath` не читается; `play_track.dart:20,49-55` — `path` передаётся в extra, но выбор трека идёт только по `index`. Либо реализовать, либо удалить.
- [ ] **P2-4. Раздутый `pages/player/service.dart` (465 строк, 5 классов).** Комментарии-заглушки `:106-108,128-130,308-310,356-358,395-397` уже указывают на ожидаемоеSplit по файлам (`player_state.dart`, `player_audio_manager.dart`, …). Разнести, заодно убрать дублирование состояния с `PlayerStateListener`.
- [ ] **P2-5. Дублирование UI.** Карточки треков копируются в `song_list/ui.dart:26-162`, `playlist/playlist.dart:136-207`, `favorite_songs_page.dart:126-201`; FutureBuilder-отчёты — в `stat/{top_stat,montly_stat,annual_stat}.dart`; паттерн «загрузка → setState → ListView → MiniPlayer» — в четырёх экранах. Вынести `TrackTile`, `StatList`, `MiniPlayerScaffold`.
- [ ] **P2-6. `getCountTrack()` считает не треки.** `core/db/crud.dart:122-133` считает строки `playlist_tracks`, а результат показывается как «Всего треков» (`music_list_page.dart:179-185`). `COUNT(DISTINCT track_id)`.
- [ ] **P2-7. Мёртвые/опасные хелперы.** `features/player/player_control.dart:5-23` — `songs[index-1]` при `index == 0` даёт `songs[songs.length]`, `nextSong + 5` — out-of-range;unctions не используются. `queue/queue.dart:23-31` — `currentIndex = 0` меняет только локальный параметр; `:33-55` не используются. `features/player/play_music.dart:8` — второй `AudioPlayer`, не используется. Удалить или переписать с модульной арифметикой.
- [ ] **P2-8. Адаптивность и доступность.** `home/ui.dart:136-145` (шрифт 56 без `maxLines`/overflow), `player/ui.dart:27-39` (обложка 260×260), `:133-179` (Row из 5 кнопок), `play_track.dart:140-181` — риск overflow на узких/низких экранах. Добавить `Flexible`/`FittedBox`, `maxLines: 1, overflow: ellipsis`, `MediaQuery.textScalerOf`, tooltip/semanticLabel для иконок без подписей (`player/ui.dart:144-170`, `home/ui.dart:110-121`).
- [ ] **P2-9. Локализация.** Строки перемешаны: английские (`service.dart:95-97` 'Unknown Title/Artist', `home/ui.dart:150,177,204`, tooltips в `player/ui.dart`) и русские (`music_list_page.dart:73,174`, `ui_widgets.dart:60,100,111`). `pubspec.yaml` не включает `generate: true`, нет `l10n.yaml`. Вынести строки в ARB.
- [ ] **P2-10. Дизайн-система не подключена.** `design/colors.dart:3-8` описывает 6 цветов, но `main.dart:26-31` не использует их; цвета хардкодятся (`home.dart:61,114,161`, `player/ui_widgets.dart:30`, `home/ui.dart:216`). Собрать `ThemeData(colorScheme: ...)`, заменить хардкод на `Theme.of(context).colorScheme`.
- [ ] **P2-11. Утечка ресурсов обложки.** `design/art.dart:33-41` — нет `picture.dispose()`/`img.dispose()`, `byteData!`, один и тот же путь `notification_gradient.png` в temp, кеш пути в `audio_handler.dart:11,38-52` не проверяет существование файла. Добавить disposal, уникальный файл/bytes in-memory и проверку `File.existsSync()`.
- [ ] **P2-12. `onTaskRemoved` останавливает музыку.** `audio_handler.dart:142-144` при `androidNotificationOngoing: true` (`audio.dart:12`). Либо убрать остановку, либо убрать ongoing-флаг и задокументировать поведение.

---

## P3 — качество и техдолг

- [ ] **P3-1. Анализатор.** 62 замечания (0 ошибок): перевести `PlayerLogic` в настоящий `ChangeNotifier`-сабкласс (или убрать `extends ChangeNotifier`) — уйдут 28 предупреждений `invalid_use_of_protected_member`; `use_key` для публичных виджетов; импорт `dart:ui` в `player_holder.dart` уже убран (`VoidCallback` есть в `material.dart`), в `audio_handler.dart` добавлен `dart:async`; `prefer_final_fields` в `music_service.dart:11`. Неиспользуемый импорт `load_tracks.dart` из `main.dart` уже убран.
- [ ] **P3-2. Deprecated API.** 28 вызовов `Color.withOpacity` заменить на `withValues(...)` (`favorite_songs_page.dart:130-150`, `home.dart:117-175`, `home/ui.dart:104,259`, `player/ui.dart:32`, `playlist*.dart`, `song_list/ui.dart`, `edit_info.dart:39`).
- [ ] **P3-3. Форматирование.** `dart format lib test` — 43 из 48 файлов. Добавить в CI проверку `dart format --output=none --set-exit-if-changed lib test`.
- [ ] **P3-4. Ужесточить линты.** В `analysis_options.yaml:23-25` включить `unawaited_futures`, `discarded_futures`, `strict-casts`, `avoid_dynamic_calls`, `use_build_context_synchronously`; это поймает значительную часть багов выше на этапе компиляции.
- [ ] **P3-5. Зависимости.** `flutter_native_splash` и `flutter_launcher_icons` (`pubspec.yaml:16-17`) — build-time утилиты, перенести в `dev_dependencies`; `just_audio_background` — beta-версия `^0.0.1-beta.17` и не используется в коде; `provider`/`shared_preferences` либо начать использовать, либо удалить.
- [ ] **P3-6. Мёртвые файлы.** Пустые `lib/core/db/db_test.dart`, `lib/features/player/player_manager.dart`, `test/widget_test.dart`; закомментированные блоки в `music_library.dart:45-60`, `audio_handler.dart:102-139`, `main.dart:17`. Удалить либо наполнить.
- [ ] **P3-7. Имена/строки.** `songsss` (`service.dart:420`), `__PlaylistFormOverlayState` (`create_playlist.dart:19`), аббревиатуры `dh/ps/ss/pv`, опечатка в имени файла `montly_stat.dart`, `title: 'My App'` (`main.dart:25`), `description: "A new Flutter project."` (`pubspec.yaml:2`).
- [ ] **P3-8. Документация.** `README.md:102,108` — лишние тройные backticks (markdown сломан); `:86` заявляет `State Management: provider`, хотя реально `setState` + синглтоны; `:70` предписывает `pod install` при отсутствующем Podfile; `:27` «coming soon» для desktop без поддержки в коде.
- [ ] **P3-9. Репозиторий.** `android/build/reports/problems/problems-report.html` — сгенерированный отчёт под версией; `android/key.properties` и `key.jks` уже в `.gitignore` (хорошо), но ключ для release всё равно не подключён (P0-9).

---

## Тесты: минимальный план покрытия

1. **Unit, чистые функции:** `QueueService.makeQueue/shuffle` — пустой список, первый/последний индекс, один трек; `player_control.dart` после исправления.
2. **Unit, БД (in-memory через `sqflite_common_ffi`):** схема/миграции 1→2→3, `resetDatabase`, уникальные ограничения, atomарный инкремент статистики, контракты `getAllTracks`/`getSongsFromPlaylist`/`getTrackInfoById`.
3. **Unit, сервисы:** `TrackLoaderService` — отказ в разрешении → ошибка → успешный повтор (проверка сброса `error`), параллельные вызовы; `PlayerLogic` — next/prev/repeat/favorite, пустая очередь, `updateCount(trackId)`.
4. **Widget:** роутер без `extra` (deep link), страницы со списками при 0/5/30 треках, disposal плеера (подписки сняты), обновление мини-плеера после удаления/избранного.
5. **Integration:** запуск → автосканирование → выбор трека → воспроизведение → скрытие приложения → next/prev из уведомления → перезапуск (восстановление очереди).

Для тестируемости понадобится заменить globals на DI: интерфейсы `DatabaseSource`, `TrackMetadataSource`, `AudioController`, инъекция `databaseFactory`; сейчас любой импорт `pages/player/service.dart` требует проинициализированного `audioHandler` (`audio.dart:4`), иначе `LateInitializationError`.

---

## Рекомендуемый порядок работ

1. ✅ **Итерация 1 — стабильность (выполнено, кроме bundle id):** P0-1…P0-8 и большая часть P0-9 + базовые unit-тесты. `flutter analyze` без ошибок, `flutter test` зелёный. Осталось решить вопрос с bundle id.
2. **Итерация 2 — состояние и данные:** P1-1…P1-9, DI и единый источник правды для плеера/избранного, миграции БД с тестами.
3. **Итерация 3 — навигация/фон/платформы:** P1-10…P1-16, media session, автовосстановление очереди, permission flow.
4. **Итерация 4 — UX и качество:** P2, P3, локализация, дизайн-система, CI.
