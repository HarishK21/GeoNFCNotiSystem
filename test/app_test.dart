import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geo_tap_guardian/app/app.dart';

void main() {
  testWidgets('opens parent flow from role selection', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GeoTapGuardianApp()));

    expect(find.text('GeoTap Guardian'), findsOneWidget);
    expect(find.text('Parent/Guardian'), findsOneWidget);

    final parentButton = find.text('Open Parent/Guardian view');
    await tester.ensureVisible(parentButton);
    await tester.tap(parentButton);
    await tester.pumpAndSettle();

    expect(find.text('Parent Overview'), findsOneWidget);
    expect(find.text('Dismissal status at a glance'), findsOneWidget);
  });

  testWidgets('opens staff flow from role selection', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GeoTapGuardianApp()));

    final staffButton = find.text('Open Teacher/Staff view');
    await tester.ensureVisible(staffButton);
    await tester.tap(staffButton);
    await tester.pumpAndSettle();

    expect(find.text('Staff Queue'), findsOneWidget);
    expect(find.text('Live release queue'), findsOneWidget);
  });
}
