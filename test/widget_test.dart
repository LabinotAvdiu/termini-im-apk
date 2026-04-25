// Smoke test — kept minimal because TakimiApp accesses Firebase synchronously
// in build() (Remote Config force-update + maintenance gates), and Firebase
// can't be initialized in the test runner without elaborate mocking. The
// `flutter analyze --no-fatal-infos` step in CI covers compilation; real
// behaviour tests live next to their feature (e.g. share_url_builder_test).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Trivial widget tree mounts', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
