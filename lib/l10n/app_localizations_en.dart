// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dot Music';

  @override
  String get back => 'Back';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get initializing => 'Initializing...';

  @override
  String get initializingPlugin => 'Initializing plugin...';

  @override
  String get loadingTracks => 'Loading tracks...';

  @override
  String get addingTracks => 'Adding tracks to the library...';

  @override
  String get loadError => 'Loading error';

  @override
  String get scanLibrary => 'Rescan library';

  @override
  String get playlists => 'Playlists';

  @override
  String get createPlaylist => 'Create playlist';

  @override
  String get createPlaylistTitle => 'New playlist';

  @override
  String get playlistNameLabel => 'Playlist name';

  @override
  String get enterPlaylistName => 'Enter a playlist name';

  @override
  String get allTracks => 'All tracks';

  @override
  String get favorites => 'Favorites';

  @override
  String get statistics => 'Statistics';

  @override
  String totalTracks(int count) {
    return 'Total: $count';
  }

  @override
  String get tracksNotFound => 'No tracks found';

  @override
  String get noFavoriteTracks => 'No favorite tracks';

  @override
  String get noTracksAvailable => 'No tracks available';

  @override
  String get favoritesEmpty => 'Favorites are empty';

  @override
  String get trackListEmpty => 'The track list is empty';

  @override
  String get unknownTrack => 'Unknown track';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get noName => 'Untitled';

  @override
  String createdAt(String date) {
    return 'Created: $date';
  }

  @override
  String get unknownDate => 'unknown';

  @override
  String get delete => 'Delete';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get openPlaylist => 'Open playlist';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get edit => 'Edit';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get trackActions => 'Track actions';

  @override
  String get selectPlaylist => 'Choose a playlist';

  @override
  String get coverArt => 'Track artwork';

  @override
  String get playlistIcon => 'Playlist';

  @override
  String get titleChanged => 'Title changed';

  @override
  String trackAddedToPlaylist(String playlist) {
    return 'Track added to \"$playlist\"';
  }

  @override
  String get trackRemovedFromLibrary => 'Track removed from the library';

  @override
  String get updateError => 'Failed to update the list';

  @override
  String get deleteTrackError => 'Failed to delete the track';

  @override
  String get addToPlaylistError => 'Failed to add to playlist';

  @override
  String get repeatOff => 'Repeat off';

  @override
  String get repeatOne => 'Repeat one';

  @override
  String get randomOrder => 'Random order';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get previousTrack => 'Previous track';

  @override
  String get nextTrack => 'Next track';

  @override
  String get queue => 'Queue';

  @override
  String playbackCount(int count) {
    return 'Plays: $count';
  }

  @override
  String playerStartError(String error) {
    return 'Failed to start the player: $error';
  }

  @override
  String playbackError(String error) {
    return 'Playback error: $error';
  }

  @override
  String get favoritesChangedError => 'Failed to update favorites';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String routeOpenError(String route) {
    return 'Could not open: $route';
  }

  @override
  String get goHome => 'Go home';

  @override
  String get globalTopTracks => '🏆 Global Top Tracks';

  @override
  String get monthStats => '📅 Current Month Stats';

  @override
  String get yearStats => '📆 Current Year Stats';

  @override
  String get topTracks => '🏆 Top tracks';

  @override
  String get monthlyStatistics => '📅 Monthly statistics';

  @override
  String get yearlyStatistics => '📆 Yearly statistics';

  @override
  String get allMusicTracks => 'Music tracks';

  @override
  String get editSongTitle => 'Edit song title';

  @override
  String topForPeriod(String period) {
    return 'Top for $period';
  }

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get noData => 'No data available';

  @override
  String get globalTop => '🏆 Global Top';

  @override
  String get permissionDenied => 'Library access denied';
}
