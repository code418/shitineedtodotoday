import 'package:flutter/painting.dart';

/// Soft, low-spread, faint-blue-tinted shadows. Cards lift gently; the primary
/// CTA carries a coloured brand shadow. Ported from `tokens/spacing.css`.
abstract final class AppShadows {
  // Alphas below derive from the ink base #1B1D29 (e.g. 0x0F ≈ 6% opacity).
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0F1B1D29), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x121B1D29), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F1B1D29), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0A1B1D29), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x1A1B1D29), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> pop = [
    BoxShadow(color: Color(0x291B1D29), blurRadius: 40, offset: Offset(0, 16)),
  ];

  static const List<BoxShadow> brand = [
    BoxShadow(color: Color(0x4D4C6FFF), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> danger = [
    BoxShadow(color: Color(0x47E5484D), blurRadius: 16, offset: Offset(0, 6)),
  ];
}
