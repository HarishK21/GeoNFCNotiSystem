import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_tap_guardian/app/app.dart';

void main() {
  testWidgets('sign-in screen opens and parent demo routes to parent flow', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GeoTapGuardianApp()));
    await tester.pumpAndSettle();

    expect(find.text('GeoTap Guardian'), findsOneWidget);
    expect(find.text('Continue as Parent Demo'), findsOneWidget);

    await tester.tap(find.text('Continue as Parent Demo'));
    await tester.pumpAndSettle();

    expect(find.text('Today\'s Pickup Plan'), findsOneWidget);
    expect(find.text('Android geofencing'), findsOneWidget);
  });

  testWidgets('staff demo routes to guarded staff flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GeoTapGuardianApp()));
    await tester.pumpAndSettle();

    final staffButton = find.text('Continue as Staff Demo');
    await tester.ensureVisible(staffButton);
    await tester.tap(staffButton);
    await tester.pumpAndSettle();

    expect(find.text('Staff Queue'), findsOneWidget);
    expect(find.text('Live release queue'), findsOneWidget);
  });
}
