class Schema {
  static const String createTracksTable = '''
    CREATE TABLE tracks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      artist TEXT,
      path TEXT,
      playback_count INTEGER,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String createPlaylistsTable = '''
    CREATE TABLE playlists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String createPlaylistTracksTable = '''
    CREATE TABLE playlist_tracks (
      playlist_id INTEGER NOT NULL,
      track_id INTEGER NOT NULL,
      added_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (playlist_id, track_id),
      FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
      FOREIGN KEY (track_id) REFERENCES tracks (id) ON DELETE CASCADE
    );
  ''';

  static const String createStatTable = '''
    CREATE TABLE listening_stat (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      track_id INTEGER NOT NULL,
      month TEXT NOT NULL,
      playback_count INTEGER DEFAULT 0,

      FOREIGN KEY (track_id) REFERENCES tracks (id) ON DELETE CASCADE
    );
  ''';

  static List<String> get createTables => [
        createTracksTable,
        createPlaylistsTable,
        createPlaylistTracksTable,
        createStatTable
      ];
}
