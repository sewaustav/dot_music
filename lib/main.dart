import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:dot_music/core/router.dart';
import 'package:dot_music/core/db/db.dart';


void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final dbHelper = DatabaseHelper();
    await dbHelper.db;
    runApp(DotMusic());
}

class DotMusic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'My App',
      theme: ThemeData(
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            iconTheme: IconThemeData(color: Colors.white), // Белые иконки в AppBar
        ),
      ),
    );
  }
}