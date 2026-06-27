import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/widgets/app_switch.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('toggling the AppSwitch flips profanity mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    expect(find.byType(AppSwitch), findsOneWidget);
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(prefs.getBool('profanity_enabled'), isTrue);
  });
}
