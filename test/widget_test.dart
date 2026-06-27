import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/app/app.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';

void main() {
  testWidgets('Today screen renders its empty state', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SnitdApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Nothing on your list today'), findsOneWidget);
    // Firebase is not configured in tests, so the notice should be shown.
    expect(find.textContaining('Firebase is not configured'), findsOneWidget);
  });
}
