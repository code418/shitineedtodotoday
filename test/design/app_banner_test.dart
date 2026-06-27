import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_banner.dart';

void main() {
  testWidgets('renders its message and a leading icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBanner(
            message: 'You are offline',
            tone: AppBannerTone.offline,
          ),
        ),
      ),
    );
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });
}
