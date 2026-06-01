import 'package:example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExampleApp renders without crashing', (tester) async {
    // The plugin's method channel has no native side under flutter test, so
    // stub it out before the home page wires up its callback in initState.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('windows_notification'),
      (call) async => null,
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('windows_notification'),
        null,
      );
    });

    await tester.pumpWidget(const ExampleApp());
    expect(find.byType(ExampleApp), findsOneWidget);
  });
}
