// test/design/app_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_card.dart';

void main() {
  testWidgets('renders child and fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            interactive: true,
            onTap: () => taps++,
            child: const Text('hello'),
          ),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
    await tester.tap(find.text('hello'));
    expect(taps, 1);
  });
}
