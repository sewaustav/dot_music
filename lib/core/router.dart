import 'package:dot_music/features/pages/music_list.dart';
import 'package:dot_music/features/pages/play_track.dart';
import 'package:dot_music/features/pages/play_track_pl.dart';
import 'package:dot_music/features/pages/playlist/playlist.dart';
import 'package:dot_music/features/pages/playlist/playlist_list.dart';
import 'package:dot_music/features/pages/stat/annual_stat.dart';
import 'package:dot_music/features/pages/stat/montly_stat.dart';
import 'package:dot_music/features/pages/stat/stat_page.dart';
import 'package:dot_music/features/pages/stat/top_stat.dart';
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
            final path = extra["songData"] as String;
            final index = extra["index"] as int; 
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
            final path = extra["songData"] as String; 
            final index = extra["index"] as int; 
            final playlist = extra["playlist"] as int;
            final page = PlayerPage(path: path, index: index, playlist: playlist);
            return page;
          },
        ),
        GoRoute(
          path: "/statistic",
          builder: (context, state) => const StatPage()
        ),
        GoRoute(
          path: "/statistic/top",
          builder: (context, state) => const TopStatPage()
        ),
        GoRoute(
          path: "/statistic/month",
          builder: (context, state) {
            final month = state.extra as int;
            return MonthlyStatPage(month: month);
          }
        ),
        GoRoute(
          path: "/statistic/year",
          builder: (context, state) {
            final year = state.extra as int;
            return AnnualStatPage(year: year);
          }
        ),

    ]
);