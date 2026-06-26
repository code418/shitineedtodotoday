import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/app/app.dart';

void main() {
  testWidgets('Today screen renders its empty state', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SnitdApp()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Nothing on your list today'), findsOneWidget);
    // Firebase is not configured in tests, so the notice should be shown.
    expect(find.textContaining('Firebase is not configured'), findsOneWidget);
  });
}
