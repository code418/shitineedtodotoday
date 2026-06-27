import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_colors.dart';

void main() {
  test('brand seed and key aliases resolve to design-system values', () {
    expect(AppColors.brand, const Color(0xFF4C6FFF));
    expect(AppColors.surfacePage, const Color(0xFFF6F7FB));
    expect(AppColors.surfaceCard, const Color(0xFFFFFFFF));
    expect(AppColors.done, AppColors.green500);
    expect(AppColors.reschedule, AppColors.coral500);
    expect(AppColors.today, AppColors.sun500);
    expect(AppColors.error, AppColors.red500);
    expect(AppColors.textPrimary, const Color(0xFF1B1D29));
  });
}
