// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Dot Music';

  @override
  String get back => 'Назад';

  @override
  String get retry => 'Повторить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get create => 'Создать';

  @override
  String get initializing => 'Инициализация...';

  @override
  String get initializingPlugin => 'Инициализация плагина...';

  @override
  String get loadingTracks => 'Загрузка треков...';

  @override
  String get addingTracks => 'Добавляем треки в базу...';

  @override
  String get loadError => 'Ошибка загрузки';

  @override
  String get scanLibrary => 'Пересканировать библиотеку';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get createPlaylist => 'Создать плейлист';

  @override
  String get createPlaylistTitle => 'Новый плейлист';

  @override
  String get playlistNameLabel => 'Название плейлиста';

  @override
  String get enterPlaylistName => 'Введите название плейлиста';

  @override
  String get allTracks => 'Все треки';

  @override
  String get favorites => 'Избранное';

  @override
  String get statistics => 'Статистика';

  @override
  String totalTracks(int count) {
    return 'Всего: $count';
  }

  @override
  String get tracksNotFound => 'Треки не найдены';

  @override
  String get noFavoriteTracks => 'Нет избранных треков';

  @override
  String get noTracksAvailable => 'Нет доступных треков';

  @override
  String get favoritesEmpty => 'Избранное пусто';

  @override
  String get trackListEmpty => 'Список треков пуст';

  @override
  String get unknownTrack => 'Неизвестный трек';

  @override
  String get unknownArtist => 'Неизвестный исполнитель';

  @override
  String get noName => 'Без названия';

  @override
  String createdAt(String date) {
    return 'Создан: $date';
  }

  @override
  String get unknownDate => 'неизвестно';

  @override
  String get delete => 'Удалить';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String get openPlaylist => 'Открыть плейлист';

  @override
  String get removeFromPlaylist => 'Удалить из плейлиста';

  @override
  String get removeFromFavorites => 'Убрать из избранного';

  @override
  String get edit => 'Редактировать';

  @override
  String get play => 'Воспроизвести';

  @override
  String get pause => 'Пауза';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String get trackActions => 'Действия с треком';

  @override
  String get selectPlaylist => 'Выберите плейлист';

  @override
  String get coverArt => 'Обложка трека';

  @override
  String get playlistIcon => 'Плейлист';

  @override
  String get titleChanged => 'Название изменено';

  @override
  String trackAddedToPlaylist(String playlist) {
    return 'Трек добавлен в «$playlist»';
  }

  @override
  String get trackRemovedFromLibrary => 'Трек удалён из библиотеки';

  @override
  String get updateError => 'Ошибка обновления списка';

  @override
  String get deleteTrackError => 'Ошибка удаления трека';

  @override
  String get addToPlaylistError => 'Ошибка добавления в плейлист';

  @override
  String get repeatOff => 'Повтор выключен';

  @override
  String get repeatOne => 'Повтор трека';

  @override
  String get randomOrder => 'Случайный порядок';

  @override
  String get shuffle => 'Перемешать';

  @override
  String get previousTrack => 'Предыдущий трек';

  @override
  String get nextTrack => 'Следующий трек';

  @override
  String get queue => 'Очередь';

  @override
  String playbackCount(int count) {
    return 'Воспроизведений: $count';
  }

  @override
  String playerStartError(String error) {
    return 'Не удалось запустить плеер: $error';
  }

  @override
  String playbackError(String error) {
    return 'Ошибка воспроизведения: $error';
  }

  @override
  String get favoritesChangedError => 'Не удалось изменить избранное';

  @override
  String get pageNotFound => 'Страница не найдена';

  @override
  String routeOpenError(String route) {
    return 'Не удалось открыть: $route';
  }

  @override
  String get goHome => 'На главную';

  @override
  String get globalTopTracks => '🏆 Топ треков';

  @override
  String get monthStats => '📅 Статистика за месяц';

  @override
  String get yearStats => '📆 Статистика за год';

  @override
  String get topTracks => '🏆 Топ треков';

  @override
  String get monthlyStatistics => '📅 Статистика за месяц';

  @override
  String get yearlyStatistics => '📆 Статистика за год';

  @override
  String get allMusicTracks => 'Музыкальные треки';

  @override
  String get editSongTitle => 'Изменить название трека';

  @override
  String topForPeriod(String period) {
    return 'Топ за $period';
  }

  @override
  String errorWithMessage(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get noData => 'Нет данных';

  @override
  String get globalTop => '🏆 Глобальный топ';

  @override
  String get permissionDenied => 'Нет доступа к медиатеке';

  @override
  String get sortTracks => 'Сортировка треков';

  @override
  String get sortByPopularity => 'По популярности';

  @override
  String get sortByAlphabet => 'По алфавиту';

  @override
  String get sortByDateAdded => 'По времени добавления';
}
