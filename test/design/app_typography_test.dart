// test/design/app_typography_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_typography.dart';

void main() {
  test('families and key sizes are correct', () {
    expect(AppTypography.fontSans, 'Nunito');
    expect(AppTypography.fontMono, 'JetBrains Mono');
    expect(AppTypography.title, 17.0);
  });
  test('textTheme uses Nunito and the display scale', () {
    final theme = AppTypography.textTheme(Brightness.light);
    expect(theme.displayLarge!.fontFamily, 'Nunito');
    expect(theme.displayLarge!.fontSize, 40.0);
    expect(theme.titleMedium!.fontSize, 17.0);
  });
  test('mono() builds a JetBrains Mono style', () {
    expect(AppTypography.mono().fontFamily, 'JetBrains Mono');
  });
}
