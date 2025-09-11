import 'package:dot_music/features/pages/music_list.dart';
import 'package:flutter/material.dart';
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
    ]
);