import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/app/app.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';

void main() {
  testWidgets('HomeShell shows 4-tab NavigationBar and tabs mount correctly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SnitdApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Shell renders with a NavigationBar.
    expect(find.byType(NavigationBar), findsOneWidget);

    // All four nav destination labels are present.
    expect(find.text('Today'), findsWidgets); // AppBar + nav label
    expect(find.text('Schedule'), findsWidgets); // AppBar + nav label
    expect(find.text('Insights'), findsWidgets); // AppBar + nav label
    expect(find.text('You'), findsOneWidget); // nav label only

    // Today tab is the initial tab; its empty state is visible.
    expect(find.text('Nothing on your list today'), findsOneWidget);

    // Tap the Insights nav destination; no crash and period toggle renders.
    await tester.tap(find.byIcon(AppIcons.insights).first);
    await tester.pumpAndSettle();
    expect(find.text('Week'), findsWidgets);

    // Tap the You nav destination; no crash and profanity row renders.
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.text('Profanity mode'), findsOneWidget);
  });
}
