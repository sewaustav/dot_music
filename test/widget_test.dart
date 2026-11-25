import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Минимальный smoke-тест: проверяет, что тестовая обвязка Flutter работает.
// Приложение целиком здесь не поднимаем — оно требует БД, прав доступа к
// медиатеке и инициализированного AudioHandler.
void main() {
  testWidgets('smoke: MaterialApp рендерит текст', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Dot Music'))),
    );

    expect(find.text('Dot Music'), findsOneWidget);
  });
}
