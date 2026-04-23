import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExampleApp()));
    expect(find.byType(ExampleApp), findsOneWidget);
  });
}
