import 'package:dot_music/features/pages/music_list.dart';
import 'package:dot_music/features/pages/play_track.dart';
import 'package:dot_music/features/pages/play_track_pl.dart';
import 'package:dot_music/features/pages/playlist.dart';
import 'package:dot_music/features/pages/playlist_list.dart';
import 'package:go_router/go_router.dart';
import 'package:dot_music/features/pages/home.dart';



final router = GoRouter(
    initialLocation: "/",
    routes: [
        GoRoute(
            path: "/",
            builder: (context, state) => const HomePage()
        ),
        GoRoute(
            path: "/list",
            builder: (context, state) => const SongListWidget()
        ),
        GoRoute(
          path: "/track",
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            final path = extra["songData"] as String; // Предполагается, что song.data — это строка
            final index = extra["index"] as int; // Предполагается, что index — это int
            final page = PlayTrackPage(path: path, index: index);
            return page;
          },
        ),
        GoRoute(
          path: "/playlists",
          builder: (context, state) {
            final extra = state.extra as int;
            return PlaylistPage(playlist: extra);
          }
        ),
        GoRoute(
          path: "/listpl",
          builder: (context, state) => const PlaylistsListPage()
        ),
        GoRoute(
          path: "/player",
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            final path = extra["songData"] as String; // Предполагается, что song.data — это строка
            final index = extra["index"] as int; // Предполагается, что index — это int
            final playlist = extra["playlist"] as int;
            final page = PlayerPage(path: path, index: index, playlist: playlist,);
            return page;
          },
        ),

    ]
);