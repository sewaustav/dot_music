import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Dot Music'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get create;

  /// No description provided for @initializing.
  ///
  /// In ru, this message translates to:
  /// **'Инициализация...'**
  String get initializing;

  /// No description provided for @initializingPlugin.
  ///
  /// In ru, this message translates to:
  /// **'Инициализация плагина...'**
  String get initializingPlugin;

  /// No description provided for @loadingTracks.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка треков...'**
  String get loadingTracks;

  /// No description provided for @addingTracks.
  ///
  /// In ru, this message translates to:
  /// **'Добавляем треки в базу...'**
  String get addingTracks;

  /// No description provided for @loadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки'**
  String get loadError;

  /// No description provided for @scanLibrary.
  ///
  /// In ru, this message translates to:
  /// **'Пересканировать библиотеку'**
  String get scanLibrary;

  /// No description provided for @playlists.
  ///
  /// In ru, this message translates to:
  /// **'Плейлисты'**
  String get playlists;

  /// No description provided for @createPlaylist.
  ///
  /// In ru, this message translates to:
  /// **'Создать плейлист'**
  String get createPlaylist;

  /// No description provided for @createPlaylistTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый плейлист'**
  String get createPlaylistTitle;

  /// No description provided for @playlistNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название плейлиста'**
  String get playlistNameLabel;

  /// No description provided for @enterPlaylistName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название плейлиста'**
  String get enterPlaylistName;

  /// No description provided for @allTracks.
  ///
  /// In ru, this message translates to:
  /// **'Все треки'**
  String get allTracks;

  /// No description provided for @favorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favorites;

  /// No description provided for @statistics.
  ///
  /// In ru, this message translates to:
  /// **'Статистика'**
  String get statistics;

  /// No description provided for @totalTracks.
  ///
  /// In ru, this message translates to:
  /// **'Всего: {count}'**
  String totalTracks(int count);

  /// No description provided for @tracksNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Треки не найдены'**
  String get tracksNotFound;

  /// No description provided for @noFavoriteTracks.
  ///
  /// In ru, this message translates to:
  /// **'Нет избранных треков'**
  String get noFavoriteTracks;

  /// No description provided for @noTracksAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных треков'**
  String get noTracksAvailable;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Избранное пусто'**
  String get favoritesEmpty;

  /// No description provided for @trackListEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Список треков пуст'**
  String get trackListEmpty;

  /// No description provided for @unknownTrack.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный трек'**
  String get unknownTrack;

  /// No description provided for @unknownArtist.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный исполнитель'**
  String get unknownArtist;

  /// No description provided for @noName.
  ///
  /// In ru, this message translates to:
  /// **'Без названия'**
  String get noName;

  /// No description provided for @createdAt.
  ///
  /// In ru, this message translates to:
  /// **'Создан: {date}'**
  String createdAt(String date);

  /// No description provided for @unknownDate.
  ///
  /// In ru, this message translates to:
  /// **'неизвестно'**
  String get unknownDate;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @deletePlaylist.
  ///
  /// In ru, this message translates to:
  /// **'Удалить плейлист'**
  String get deletePlaylist;

  /// No description provided for @openPlaylist.
  ///
  /// In ru, this message translates to:
  /// **'Открыть плейлист'**
  String get openPlaylist;

  /// No description provided for @removeFromPlaylist.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из плейлиста'**
  String get removeFromPlaylist;

  /// No description provided for @removeFromFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из избранного'**
  String get removeFromFavorites;

  /// No description provided for @edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get edit;

  /// No description provided for @play.
  ///
  /// In ru, this message translates to:
  /// **'Воспроизвести'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get pause;

  /// No description provided for @addToPlaylist.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в плейлист'**
  String get addToPlaylist;

  /// No description provided for @trackActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия с треком'**
  String get trackActions;

  /// No description provided for @selectPlaylist.
  ///
  /// In ru, this message translates to:
  /// **'Выберите плейлист'**
  String get selectPlaylist;

  /// No description provided for @coverArt.
  ///
  /// In ru, this message translates to:
  /// **'Обложка трека'**
  String get coverArt;

  /// No description provided for @playlistIcon.
  ///
  /// In ru, this message translates to:
  /// **'Плейлист'**
  String get playlistIcon;

  /// No description provided for @titleChanged.
  ///
  /// In ru, this message translates to:
  /// **'Название изменено'**
  String get titleChanged;

  /// No description provided for @trackAddedToPlaylist.
  ///
  /// In ru, this message translates to:
  /// **'Трек добавлен в «{playlist}»'**
  String trackAddedToPlaylist(String playlist);

  /// No description provided for @trackRemovedFromLibrary.
  ///
  /// In ru, this message translates to:
  /// **'Трек удалён из библиотеки'**
  String get trackRemovedFromLibrary;

  /// No description provided for @updateError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка обновления списка'**
  String get updateError;

  /// No description provided for @deleteTrackError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка удаления трека'**
  String get deleteTrackError;

  /// No description provided for @addToPlaylistError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка добавления в плейлист'**
  String get addToPlaylistError;

  /// No description provided for @repeatOff.
  ///
  /// In ru, this message translates to:
  /// **'Повтор выключен'**
  String get repeatOff;

  /// No description provided for @repeatOne.
  ///
  /// In ru, this message translates to:
  /// **'Повтор трека'**
  String get repeatOne;

  /// No description provided for @randomOrder.
  ///
  /// In ru, this message translates to:
  /// **'Случайный порядок'**
  String get randomOrder;

  /// No description provided for @shuffle.
  ///
  /// In ru, this message translates to:
  /// **'Перемешать'**
  String get shuffle;

  /// No description provided for @previousTrack.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий трек'**
  String get previousTrack;

  /// No description provided for @nextTrack.
  ///
  /// In ru, this message translates to:
  /// **'Следующий трек'**
  String get nextTrack;

  /// No description provided for @queue.
  ///
  /// In ru, this message translates to:
  /// **'Очередь'**
  String get queue;

  /// No description provided for @playbackCount.
  ///
  /// In ru, this message translates to:
  /// **'Воспроизведений: {count}'**
  String playbackCount(int count);

  /// No description provided for @playerStartError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запустить плеер: {error}'**
  String playerStartError(String error);

  /// No description provided for @playbackError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка воспроизведения: {error}'**
  String playbackError(String error);

  /// No description provided for @favoritesChangedError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить избранное'**
  String get favoritesChangedError;

  /// No description provided for @pageNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Страница не найдена'**
  String get pageNotFound;

  /// No description provided for @routeOpenError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть: {route}'**
  String routeOpenError(String route);

  /// No description provided for @goHome.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get goHome;

  /// No description provided for @globalTopTracks.
  ///
  /// In ru, this message translates to:
  /// **'🏆 Топ треков'**
  String get globalTopTracks;

  /// No description provided for @monthStats.
  ///
  /// In ru, this message translates to:
  /// **'📅 Статистика за месяц'**
  String get monthStats;

  /// No description provided for @yearStats.
  ///
  /// In ru, this message translates to:
  /// **'📆 Статистика за год'**
  String get yearStats;

  /// No description provided for @topTracks.
  ///
  /// In ru, this message translates to:
  /// **'🏆 Топ треков'**
  String get topTracks;

  /// No description provided for @monthlyStatistics.
  ///
  /// In ru, this message translates to:
  /// **'📅 Статистика за месяц'**
  String get monthlyStatistics;

  /// No description provided for @yearlyStatistics.
  ///
  /// In ru, this message translates to:
  /// **'📆 Статистика за год'**
  String get yearlyStatistics;

  /// No description provided for @allMusicTracks.
  ///
  /// In ru, this message translates to:
  /// **'Музыкальные треки'**
  String get allMusicTracks;

  /// No description provided for @editSongTitle.
  ///
  /// In ru, this message translates to:
  /// **'Изменить название трека'**
  String get editSongTitle;

  /// No description provided for @topForPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Топ за {period}'**
  String topForPeriod(String period);

  /// No description provided for @errorWithMessage.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @noData.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get noData;

  /// No description provided for @globalTop.
  ///
  /// In ru, this message translates to:
  /// **'🏆 Глобальный топ'**
  String get globalTop;

  /// No description provided for @permissionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к медиатеке'**
  String get permissionDenied;

  /// No description provided for @sortTracks.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка треков'**
  String get sortTracks;

  /// No description provided for @sortByPopularity.
  ///
  /// In ru, this message translates to:
  /// **'По популярности'**
  String get sortByPopularity;

  /// No description provided for @sortByAlphabet.
  ///
  /// In ru, this message translates to:
  /// **'По алфавиту'**
  String get sortByAlphabet;

  /// No description provided for @sortByDateAdded.
  ///
  /// In ru, this message translates to:
  /// **'По времени добавления'**
  String get sortByDateAdded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
