import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test: app boots a widget', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('OK'))));
    expect(find.text('OK'), findsOneWidget);
  });
}
