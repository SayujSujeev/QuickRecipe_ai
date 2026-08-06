import 'package:flutter_test/flutter_test.dart';

import 'package:terracota/main.dart';

void main() {
  testWidgets('Home screen renders greeting', (WidgetTester tester) async {
    await tester.pumpWidget(const TerracotaApp());
    await tester.pump();

    expect(find.text('Good morning, Jamie'), findsOneWidget);
    expect(find.text('Daily Goal'), findsOneWidget);
    expect(find.text('Trending Recipes'), findsOneWidget);
  });
}
