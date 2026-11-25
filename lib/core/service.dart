import 'package:on_audio_query/on_audio_query.dart';

final OnAudioQuery _audioQuery = OnAudioQuery();
final Map<String, Map<String, dynamic>> _metadataCache = {};
bool _cacheReady = false;

/// Преобразует SongModel в формат, который ожидает БД.
/// Одна точка для сканера и одиночного поиска.
Map<String, dynamic> trackMetadata(SongModel song) => {
  'id': song.id,
  'title': song.title,
  'artist': song.artist,
  'album': song.album,
  'duration': song.duration,
  'path': song.data,
};

/// Разрешения и запрос к медиатеке выполняются один раз за сессию.
Future<void> preloadTrackMetadata() async {
  if (_cacheReady) return;
  await _audioQuery.permissionsRequest();
  final songs = await _audioQuery.querySongs(uriType: UriType.EXTERNAL);
  cacheTrackMetadata(songs);
  _cacheReady = true;
}

void cacheTrackMetadata(Iterable<SongModel> songs) {
  for (final song in songs) {
    _metadataCache[song.data] = trackMetadata(song);
  }
}

void invalidateTrackMetadata() {
  _metadataCache.clear();
  _cacheReady = false;
}

/// [metadata] полезен сканеру: он уже получил SongModel и не делает
/// повторный querySongs на каждый трек (P1-15).
Future<Map<String, dynamic>?> getTrackInfoByPath(
  String path, {
  Map<String, dynamic>? metadata,
}) async {
  if (metadata != null) return metadata;
  if (!_cacheReady) await preloadTrackMetadata();
  return _metadataCache[path];
}
