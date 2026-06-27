// test/design/app_avatar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_avatar.dart';

void main() {
  testWidgets('derives up to two uppercase initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AppAvatar(name: 'Richard Brown')),
        ),
      ),
    );
    expect(find.text('RB'), findsOneWidget);
  });

  testWidgets('falls back to ? for an empty name', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AppAvatar(name: '')),
        ),
      ),
    );
    expect(find.text('?'), findsOneWidget);
  });
}
