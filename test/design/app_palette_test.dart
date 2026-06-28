import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/app/theme.dart';
import 'package:snitd/core/design/tokens/app_colors.dart';
import 'package:snitd/core/design/tokens/app_palette.dart';

void main() {
  test('light palette mirrors the existing AppColors semantic aliases', () {
    expect(AppPalette.light.surfaceCard, AppColors.surfaceCard);
    expect(AppPalette.light.surfacePage, AppColors.surfacePage);
    expect(AppPalette.light.textPrimary, AppColors.textPrimary);
    expect(AppPalette.light.textMuted, AppColors.textMuted);
    expect(AppPalette.light.brand, AppColors.brand);
    expect(AppPalette.light.borderDefault, AppColors.borderDefault);
  });

  test('dark palette uses dark surfaces and light text', () {
    expect(AppPalette.dark.surfaceCard, AppColors.ink800);
    expect(AppPalette.dark.surfacePage, AppColors.ink900);
    expect(AppPalette.dark.textPrimary, AppColors.ink50);
    // Surfaces and text invert vs light.
    expect(AppPalette.dark.surfaceCard, isNot(AppPalette.light.surfaceCard));
    expect(AppPalette.dark.textPrimary, isNot(AppPalette.light.textPrimary));
  });

  testWidgets('context.palette resolves the light theme extension', (
    tester,
  ) async {
    late AppPalette p;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            p = context.palette;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(p.surfaceCard, AppColors.white);
  });

  testWidgets('context.palette resolves the dark theme extension', (
    tester,
  ) async {
    late AppPalette p;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            p = context.palette;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(p.surfaceCard, AppColors.ink800);
  });
}
