import 'package:dot_music/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke: MaterialApp рендерит текст', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Dot Music'))),
    );

    expect(find.text('Dot Music'), findsOneWidget);
  });

  testWidgets('DotMusic строит приложение без ошибок локализации', (
    tester,
  ) async {
    await tester.pumpWidget(const DotMusic());

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
