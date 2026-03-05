import 'package:flutter_test/flutter_test.dart';

import 'package:subinsights/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SubInsightsApp());
    expect(find.text('SubInsights'), findsOneWidget);
  });
}
