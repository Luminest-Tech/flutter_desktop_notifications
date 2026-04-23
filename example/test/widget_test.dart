import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PlaygroundApp renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PlaygroundApp());
    expect(find.byType(PlaygroundApp), findsOneWidget);
  });
}
