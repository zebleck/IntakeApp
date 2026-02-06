import 'package:flutter_test/flutter_test.dart';

import 'package:intake/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const IntakeApp());
    expect(find.text('intake'), findsOneWidget);
  });
}
