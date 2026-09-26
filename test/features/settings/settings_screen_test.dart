import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/widgets/app_switch.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/home_widget/data/home_widget_bridge.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/settings/presentation/settings_screen.dart';

import '../home_widget/widget_completer_test.dart' show FakeBridge;

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

  group('add the widget to the home screen', () {
    Future<_PinBridge> pump(WidgetTester tester, {required bool canPin}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final bridge = _PinBridge(canPin);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            homeWidgetBridgeProvider.overrideWithValue(bridge),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return bridge;
    }

    testWidgets('offered where the launcher supports it, and asks it', (
      tester,
    ) async {
      final bridge = await pump(tester, canPin: true);
      await tester.scrollUntilVisible(
        find.text(AppStrings.clean.widgetAddTitle),
        200,
      );
      await tester.tap(find.text(AppStrings.clean.widgetAddTitle));
      await tester.pumpAndSettle();
      expect(bridge.pinRequests, 1);
    });

    testWidgets('not offered where it isn\'t supported', (tester) async {
      await pump(tester, canPin: false);
      // Scroll to the bottom (the debug gallery link) — no widget card.
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.clean.widgetAddTitle), findsNothing);
    });
  });
}

class _PinBridge extends FakeBridge {
  _PinBridge(this._canPin);
  final bool _canPin;
  var pinRequests = 0;

  @override
  Future<bool> canPin() async => _canPin;

  @override
  Future<void> requestPin() async => pinRequests++;
}
