import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_badge.dart';

void main() {
  testWidgets('renders its label in a mono style', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: AppBadge(label: '~15m'))),
    ));
    expect(find.text('~15m'), findsOneWidget);
    final text = tester.widget<Text>(find.text('~15m'));
    expect(text.style!.fontFamily, 'JetBrains Mono');
  });
}
