import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/app/app.dart';
import 'package:snitd/core/design/tokens/app_colors.dart';
import 'package:snitd/core/design/tokens/app_palette.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';

Future<AppPalette> _paletteUnder(
  WidgetTester tester,
  Brightness platform,
) async {
  tester.platformDispatcher.platformBrightnessTestValue = platform;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SnitdApp(),
    ),
  );
  await tester.pumpAndSettle();

  final context = tester.element(find.byType(Scaffold).first);
  return context.palette;
}

void main() {
  testWidgets('follows the system into dark mode with dark surfaces', (
    tester,
  ) async {
    final c = await _paletteUnder(tester, Brightness.dark);
    // Dark palette: dark ink surfaces + light text (no white-on-white).
    expect(c.surfaceCard, AppColors.ink800);
    expect(c.surfacePage, AppColors.ink900);
    expect(c.textPrimary, AppColors.ink50);
  });

  testWidgets('uses the light palette when the system is light', (
    tester,
  ) async {
    final c = await _paletteUnder(tester, Brightness.light);
    expect(c.surfaceCard, AppColors.white);
    expect(c.textPrimary, AppColors.ink900);
  });
}
