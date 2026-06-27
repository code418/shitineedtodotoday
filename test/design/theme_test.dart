// test/design/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/app/theme.dart';
import 'package:snitd/core/design/tokens/app_colors.dart';

void main() {
  test('light theme uses brand primary, ink50 background and Nunito', () {
    final t = AppTheme.light();
    expect(t.colorScheme.primary, AppColors.brand);
    expect(t.scaffoldBackgroundColor, AppColors.surfacePage);
    expect(t.textTheme.titleMedium!.fontFamily, 'Nunito');
    expect(t.useMaterial3, isTrue);
  });
  test('dark theme is dark and keeps the brand hue', () {
    final t = AppTheme.dark();
    expect(t.brightness, Brightness.dark);
    expect(t.colorScheme.primary, AppColors.blue400);
  });
}
