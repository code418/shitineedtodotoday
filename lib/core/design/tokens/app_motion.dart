import 'package:flutter/widgets.dart';

/// Calm motion: ease-out by default, a small spring on confirming gestures.
/// Always route animation durations through [AppMotion.of] so they respect the
/// platform's reduced-motion setting.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  static const Cubic easeOut = Cubic(0.22, 1, 0.36, 1);
  static const Cubic soft = Cubic(0.4, 0, 0.2, 1);
  static const Cubic spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Returns [d], or [Duration.zero] when the user has asked for reduced motion.
  static Duration of(BuildContext context, Duration d) =>
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
      ? Duration.zero
      : d;
}
