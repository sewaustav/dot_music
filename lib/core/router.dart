import 'package:dot_music/features/pages/favorite_songs/favorite_songs_page.dart';
import 'package:dot_music/features/pages/home/home.dart';
import 'package:dot_music/l10n/l10n.dart';
import 'package:dot_music/features/pages/player/play_track.dart';
import 'package:dot_music/features/pages/playlist/playlist.dart';
import 'package:dot_music/features/pages/playlist/playlist_list.dart';
import 'package:dot_music/features/pages/song_list/music_list_page.dart';
import 'package:dot_music/features/pages/stat/annual_stat.dart';
import 'package:dot_music/features/pages/stat/monthly_stat.dart';
import 'package:dot_music/features/pages/stat/stat_page.dart';
import 'package:dot_music/features/pages/stat/top_stat.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Аргументы экрана плеера. Поддерживаются и `extra` ( старые вызовы ),
/// и query/path параметры (прямые ссылки, deep link, тап по уведомлению).
class PlayerRouteArgs {
  const PlayerRouteArgs({
    required this.path,
    required this.index,
    required this.playlist,
    this.fromMiniPlayer = false,
    this.returnRoute,
  });

  final String path;
  final int index;
  final int playlist;
  final bool fromMiniPlayer;
  final String? returnRoute;

  factory PlayerRouteArgs.from(GoRouterState state) => PlayerRouteArgs.parse(
    extra: state.extra,
    query: state.uri.queryParameters,
    pathParams: state.pathParameters,
  );

  /// Чистая функция: можно тестировать без GoRouter и виджетов (P1-11).
  factory PlayerRouteArgs.parse({
    Object? extra,
    Map<String, String> query = const {},
    Map<String, String> pathParams = const {},
  }) {
    final map = extra is Map ? extra : <Object?, Object?>{};

    return PlayerRouteArgs(
      path:
          _string(map['songData'] ?? map['path']) ??
          query['path'] ??
          pathParams['path'] ??
          '',
      index: _int(map['index']) ?? int.tryParse(query['index'] ?? '') ?? 0,
      playlist:
          _int(map['playlist']) ?? int.tryParse(query['playlist'] ?? '') ?? 0,
      fromMiniPlayer:
          _bool(map['fromMiniPlayer']) ?? (query['fromMiniPlayer'] == 'true'),
      returnRoute: _string(map['returnRoute']) ?? query['returnRoute'],
    );
  }

  static String? _string(Object? value) => value?.toString();

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool? _bool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value == 'true';
    return null;
  }
}

int _routeInt(GoRouterState state, String key, {int fallback = 0}) {
  final extra = state.extra;
  final fromExtra = extra is int
      ? extra
      : (extra is Map ? PlayerRouteArgs._int(extra[key]) : null);
  return fromExtra ??
      int.tryParse(state.pathParameters[key] ?? '') ??
      int.tryParse(state.uri.queryParameters[key] ?? '') ??
      fallback;
}

final router = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.pageNotFound)),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(context.l10n.routeOpenError(state.uri.toString())),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/'),
            child: Text(context.l10n.goHome),
          ),
        ],
      ),
    ),
  ),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/list', builder: (context, state) => const SongListPage()),
    GoRoute(
      path: '/playlists',
      builder: (context, state) =>
          PlaylistPage(playlist: _routeInt(state, 'playlist')),
    ),
    GoRoute(
      path: '/listpl',
      builder: (context, state) => const PlaylistsListPage(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final args = PlayerRouteArgs.from(state);
        return PlayerPage(
          path: args.path,
          index: args.index,
          playlist: args.playlist,
          fromMiniPlayer: args.fromMiniPlayer,
          returnRoute: args.returnRoute,
        );
      },
    ),
    GoRoute(path: '/statistic', builder: (context, state) => const StatPage()),
    GoRoute(
      path: '/statistic/top',
      builder: (context, state) => const TopStatPage(),
    ),
    GoRoute(
      path: '/statistic/month',
      builder: (context, state) => MonthlyStatPage(
        month: _routeInt(state, 'month', fallback: DateTime.now().month),
      ),
    ),
    GoRoute(
      path: '/statistic/year',
      builder: (context, state) => AnnualStatPage(
        year: _routeInt(state, 'year', fallback: DateTime.now().year),
      ),
    ),
    GoRoute(
      path: '/fav',
      builder: (context, state) => const FavoriteSongsPage(),
    ),
  ],
);
