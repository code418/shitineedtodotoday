# Foundation — SINTDT Design System in Flutter — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Translate the SINTDT design system into a reusable Flutter foundation (tokens, theme, fonts/icons, a 12-widget `App*` library + the signature `AppTaskItem` + `AppBrandMark`, a debug gallery) and reskin the existing Today/empty-state/Settings screens — with no product-logic changes.

**Architecture:** A token layer of `static const` holders under `lib/core/design/tokens/` is the single source of truth for colour/type/spacing/shadow/motion/icon values. `lib/app/theme.dart` consumes the tokens to build the Material `ThemeData` (faithful light + best-effort dark). Reusable, UI-agnostic widgets live in `lib/core/design/widgets/`; the task-domain `AppTaskItem` lives with its feature. Widgets read tokens directly (not via `ThemeExtension`). Animations use Flutter implicit animations and honour reduced-motion.

**Tech Stack:** Flutter (Material 3), Riverpod (plain providers), go_router, `material_symbols_icons` package, bundled variable fonts (Nunito, JetBrains Mono).

## Global Constraints

- Flutter SDK `^3.12.2`; Riverpod plain providers (no codegen); go_router for nav.
- Lint/style: single quotes, trailing commas, ordered imports. `dart format .` and `flutter analyze` must be clean; `flutter test` green.
- Widget naming: `App*` prefix (avoids Material `Card`/`Chip`/`Checkbox`/`Switch`/`Badge` name clashes; consistent with `AppTheme`/`AppStrings`).
- Token API: `abstract final class` holders of `static const`. Widgets import token files directly.
- Layering: `domain/` must not import Flutter or `presentation/`. `core/design/` is a UI layer and may import Flutter.
- Icons: Material Symbols Rounded via `material_symbols_icons` (`Symbols.*`, const → tree-shakeable). Fonts: bundled variable `.ttf` in `assets/fonts/`.
- Copy: sentence case, British English, never scolds a missed chore (reschedule = coral, never red). Task content is data, not chrome.
- No new product logic in this slice: "Add task" and suggestion taps keep the existing "coming soon" snackbar; scheduler stays stubbed.
- All commits end with the trailer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` (omitted from per-step commit commands below for brevity). Work stays on branch `feat/foundation-design-system`.
- Colour/spacing/motion values are taken verbatim from the design system tokens; per-widget pixel values are taken from the design system `.jsx` sources quoted in each task.

---

## File structure

```
assets/fonts/                       Nunito-Variable.ttf, NunitoItalic-Variable.ttf, JetBrainsMono-Variable.ttf
lib/core/design/
  tokens/
    app_colors.dart                 raw ramps + semantic aliases
    app_spacing.dart                AppSpacing / AppRadii / AppLayout
    app_shadows.dart                AppShadows (List<BoxShadow>)
    app_motion.dart                 AppMotion (durations, curves, reduced-motion helper)
    app_typography.dart             AppTypography (families, weights, sizes, textTheme)
    app_icons.dart                  AppIcons (re-exports curated Symbols.*)
    tokens.dart                     barrel for the token files
  widgets/
    app_badge.dart  app_checkbox.dart  app_card.dart  app_chip.dart
    app_button.dart  app_icon_button.dart  app_switch.dart
    app_segmented_control.dart  app_progress_meter.dart  app_avatar.dart
    app_banner.dart  app_brand_mark.dart
    widgets.dart                    barrel for the widgets
  design.dart                       top-level barrel (tokens + widgets)
  gallery/gallery_screen.dart       debug-only component gallery
lib/app/theme.dart                  rebuilt AppTheme (light + dark) — MODIFIED
lib/app/router.dart                 + /gallery route — MODIFIED
lib/features/tasks/presentation/
  widgets/task_item.dart            AppTaskItem
  today_screen.dart                 reskin — MODIFIED
lib/features/settings/presentation/
  settings_screen.dart             reskin — MODIFIED
test/design/                        one *_test.dart per widget
test/features/tasks/task_item_test.dart
```

---

### Task 1: Dependencies, fonts & icons setup

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/fonts/Nunito-Variable.ttf`, `assets/fonts/NunitoItalic-Variable.ttf`, `assets/fonts/JetBrainsMono-Variable.ttf`

**Interfaces:**
- Produces: bundled font families `Nunito` and `JetBrains Mono`; the `material_symbols_icons` package (`package:material_symbols_icons/symbols.dart` → `Symbols.*`).

- [ ] **Step 1: Download the variable fonts (OFL) into `assets/fonts/`**

```bash
mkdir -p assets/fonts
curl -fL -o assets/fonts/Nunito-Variable.ttf \
  'https://github.com/google/fonts/raw/main/ofl/nunito/Nunito%5Bwght%5D.ttf'
curl -fL -o assets/fonts/NunitoItalic-Variable.ttf \
  'https://github.com/google/fonts/raw/main/ofl/nunito/Nunito-Italic%5Bwght%5D.ttf'
curl -fL -o assets/fonts/JetBrainsMono-Variable.ttf \
  'https://github.com/google/fonts/raw/main/ofl/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf'
ls -l assets/fonts
```
Expected: three `.ttf` files, each > 100 KB. (Variable fonts cover all weights via the `wght` axis, which Flutter maps from `FontWeight`.)

- [ ] **Step 2: Add the icon dependency**

Run: `flutter pub add material_symbols_icons`
Expected: `material_symbols_icons` added under `dependencies:` in `pubspec.yaml`; `flutter pub get` succeeds.

- [ ] **Step 3: Declare the fonts in `pubspec.yaml`**

Replace the commented-out `# fonts:` block in the `flutter:` section with:

```yaml
  fonts:
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Variable.ttf
        - asset: assets/fonts/NunitoItalic-Variable.ttf
          style: italic
    - family: JetBrains Mono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Variable.ttf
```

- [ ] **Step 4: Verify the project still resolves and analyses**

Run: `flutter pub get && flutter analyze`
Expected: pub resolves; analyze reports no issues.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/fonts
git commit -m "build: bundle Nunito + JetBrains Mono fonts and add material_symbols_icons"
```

---

### Task 2: Colour tokens

**Files:**
- Create: `lib/core/design/tokens/app_colors.dart`
- Test: `test/design/app_colors_test.dart`

**Interfaces:**
- Produces: `AppColors` with raw ramps (`blue50..blue900`, `sun200..sun600`, `coral200..coral600`, `green200..green600`, `red300..red600`, `ink50..ink900`, `white`) and semantic aliases (`surfacePage`, `surfaceCard`, `surfaceSunken`, `surfaceBrand`, `textPrimary`, `textSecondary`, `textMuted`, `textOnBrand`, `textBrand`, `brand`, `brandHover`, `brandPress`, `brandSoft`, `brandSoftHover`, `done`, `doneSoft`, `reschedule`, `rescheduleSoft`, `today`, `todaySoft`, `error`, `errorSoft`, `borderSubtle`, `borderDefault`, `borderStrong`, `focusRing`).

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_colors_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_colors_test.dart`
Expected: FAIL — `app_colors.dart` / `AppColors` not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/tokens/app_colors.dart
import 'package:flutter/painting.dart';

/// SINTDT colour system — raw ramps + semantic aliases, ported verbatim from
/// the design system's `tokens/colors.css`. Reschedule states use a gentle
/// coral, never alarm-red; red is reserved for true errors.
abstract final class AppColors {
  // Brand — indigo-blue.
  static const blue50 = Color(0xFFEEF2FF);
  static const blue100 = Color(0xFFDDE4FF);
  static const blue200 = Color(0xFFBBC8FF);
  static const blue300 = Color(0xFF93A6FF);
  static const blue400 = Color(0xFF6B85FF);
  static const blue500 = Color(0xFF4C6FFF); // brand / seed
  static const blue600 = Color(0xFF3A55E6);
  static const blue700 = Color(0xFF2C41B8);
  static const blue800 = Color(0xFF22338C);
  static const blue900 = Color(0xFF1A2870);

  // Sun — warm amber.
  static const sun200 = Color(0xFFFFE6B0);
  static const sun300 = Color(0xFFFFD27A);
  static const sun400 = Color(0xFFFFC04D);
  static const sun500 = Color(0xFFFFB23E);
  static const sun600 = Color(0xFFF59A1E);

  // Coral — the forgiving "moved it for you" state.
  static const coral200 = Color(0xFFFFD8C8);
  static const coral300 = Color(0xFFFFB59A);
  static const coral400 = Color(0xFFFF9B78);
  static const coral500 = Color(0xFFFF8A5B);
  static const coral600 = Color(0xFFF26B3A);

  // Green — done / completed.
  static const green200 = Color(0xFFC5F2D8);
  static const green300 = Color(0xFF7DE0A8);
  static const green400 = Color(0xFF4FD089);
  static const green500 = Color(0xFF2FBF71);
  static const green600 = Color(0xFF1FA15D);

  // Red — true errors only.
  static const red300 = Color(0xFFF7A8AB);
  static const red400 = Color(0xFFF0696D);
  static const red500 = Color(0xFFE5484D);
  static const red600 = Color(0xFFC93B40);

  // Neutrals — soft indigo-charcoal ink ramp.
  static const ink900 = Color(0xFF1B1D29);
  static const ink800 = Color(0xFF292C3C);
  static const ink700 = Color(0xFF3A3D4D);
  static const ink600 = Color(0xFF565A6E);
  static const ink500 = Color(0xFF757A90);
  static const ink400 = Color(0xFF9AA0B4);
  static const ink300 = Color(0xFFC4C8D6);
  static const ink200 = Color(0xFFE2E5EE);
  static const ink100 = Color(0xFFEEF0F6);
  static const ink50 = Color(0xFFF6F7FB);
  static const white = Color(0xFFFFFFFF);

  // Surfaces.
  static const surfacePage = ink50;
  static const surfaceCard = white;
  static const surfaceSunken = ink100;
  static const surfaceBrand = blue500;
  static const surfaceBrandSoft = blue50;

  // Text.
  static const textPrimary = ink900;
  static const textSecondary = ink600;
  static const textMuted = ink500;
  static const textOnBrand = white;
  static const textBrand = blue600;

  // Brand interaction.
  static const brand = blue500;
  static const brandHover = blue600;
  static const brandPress = blue700;
  static const brandSoft = blue50;
  static const brandSoftHover = blue100;

  // Status.
  static const done = green500;
  static const doneSoft = green200;
  static const reschedule = coral500;
  static const rescheduleSoft = coral200;
  static const today = sun500;
  static const todaySoft = sun200;
  static const error = red500;
  static const errorSoft = red300;

  // Borders.
  static const borderSubtle = ink100;
  static const borderDefault = ink200;
  static const borderStrong = ink300;

  // Focus ring colour (3px outer glow when applied).
  static const focusRing = blue200;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_colors_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/tokens/app_colors.dart test/design/app_colors_test.dart
git commit -m "feat(design): colour tokens"
```

---

### Task 3: Spacing, radii & layout tokens

**Files:**
- Create: `lib/core/design/tokens/app_spacing.dart`
- Test: `test/design/app_spacing_test.dart`

**Interfaces:**
- Produces: `AppSpacing` (`x0`=0 … `x11`=80, the 4px scale), `AppRadii` (`xs`6, `sm`10, `md`14, `lg`18, `xl`24, `xxl`32, `pill`999), `AppLayout` (`tapMin`48, `screenPad`16, `contentMax`480). All `double`.

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_spacing_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_spacing.dart';

void main() {
  test('spacing follows the 4px grid', () {
    expect(AppSpacing.x4, 16.0);
    expect(AppSpacing.x7, 32.0);
    expect(AppSpacing.x11, 80.0);
  });
  test('radii and layout constants match the design system', () {
    expect(AppRadii.lg, 18.0);
    expect(AppRadii.xl, 24.0);
    expect(AppRadii.pill, 999.0);
    expect(AppLayout.tapMin, 48.0);
    expect(AppLayout.contentMax, 480.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_spacing_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/tokens/app_spacing.dart
/// 4px spacing grid.
abstract final class AppSpacing {
  static const double x0 = 0;
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 32;
  static const double x8 = 40;
  static const double x9 = 48;
  static const double x10 = 64;
  static const double x11 = 80;
}

/// Generously rounded corner radii.
abstract final class AppRadii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
  static const double pill = 999;
}

/// Layout constants (phone-first, Android tap targets).
abstract final class AppLayout {
  static const double tapMin = 48;
  static const double screenPad = 16;
  static const double contentMax = 480;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_spacing_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/tokens/app_spacing.dart test/design/app_spacing_test.dart
git commit -m "feat(design): spacing, radii & layout tokens"
```

---

### Task 4: Shadow tokens

**Files:**
- Create: `lib/core/design/tokens/app_shadows.dart`
- Test: `test/design/app_shadows_test.dart`

**Interfaces:**
- Produces: `AppShadows` with `List<BoxShadow>` constants: `xs`, `sm`, `card`, `raised`, `pop`, `brand` (blue-tinted).

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_shadows_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_shadows.dart';

void main() {
  test('card shadow is a soft two-layer stack; brand shadow is blue-tinted', () {
    expect(AppShadows.card.length, 2);
    expect(AppShadows.brand.first.color.blue, 255);
    expect(AppShadows.raised.first.blurRadius, 24);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_shadows_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/tokens/app_shadows.dart
import 'package:flutter/painting.dart';

/// Soft, low-spread, faint-blue-tinted shadows. Cards lift gently; the primary
/// CTA carries a coloured brand shadow. Ported from `tokens/spacing.css`.
abstract final class AppShadows {
  static const _ink = Color(0xFF1B1D29);

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

  /// Kept to document the ink base colour the alphas above derive from.
  // ignore: unused_field
  static const _base = _ink;
}
```

*(Alpha hex: 0.06≈0F, 0.07≈12, 0.04≈0A, 0.10≈1A, 0.16≈29, 0.30≈4D.)*

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_shadows_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/tokens/app_shadows.dart test/design/app_shadows_test.dart
git commit -m "feat(design): shadow tokens"
```

---

### Task 5: Motion tokens

**Files:**
- Create: `lib/core/design/tokens/app_motion.dart`
- Test: `test/design/app_motion_test.dart`

**Interfaces:**
- Produces: `AppMotion` with `Duration` constants `fast`(120ms)/`normal`(200ms)/`slow`(320ms); `Cubic` curves `easeOut`/`soft`/`spring`; and `Duration AppMotion.of(BuildContext, Duration)` that collapses to `Duration.zero` under reduced-motion.

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_motion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_motion.dart';

void main() {
  test('durations and curves match the design system', () {
    expect(AppMotion.normal, const Duration(milliseconds: 200));
    expect(AppMotion.spring, const Cubic(0.34, 1.56, 0.64, 1));
  });

  testWidgets('of() collapses to zero when animations are disabled',
      (tester) async {
    late Duration resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (context) {
          resolved = AppMotion.of(context, AppMotion.normal);
          return const SizedBox();
        }),
      ),
    );
    expect(resolved, Duration.zero);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_motion_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/tokens/app_motion.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_motion_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/tokens/app_motion.dart test/design/app_motion_test.dart
git commit -m "feat(design): motion tokens + reduced-motion helper"
```

---

### Task 6: Typography tokens & TextTheme

**Files:**
- Create: `lib/core/design/tokens/app_typography.dart`
- Test: `test/design/app_typography_test.dart`

**Interfaces:**
- Consumes: `AppColors`.
- Produces: `AppTypography` with `fontSans`='Nunito', `fontMono`='JetBrains Mono'; `FontWeight` consts `regular`(400)/`medium`(600)/`semibold`(700)/`bold`(800)/`black`(900); size consts `display`40…`size2xs`11; `TextTheme textTheme(Brightness)`; and `TextStyle mono({double size, FontWeight weight, Color color})` for durations/counts.

- [ ] **Step 1: Write the failing test**

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_typography_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/tokens/app_typography.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nunito for UI + display; JetBrains Mono for durations and counts.
/// Sentence case, generous line-height, tight tracking on large sizes.
abstract final class AppTypography {
  static const String fontSans = 'Nunito';
  static const String fontMono = 'JetBrains Mono';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w600;
  static const FontWeight semibold = FontWeight.w700;
  static const FontWeight bold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // Type scale (logical px).
  static const double display = 40;
  static const double h1 = 30;
  static const double h2 = 24;
  static const double h3 = 20;
  static const double title = 17;
  static const double body = 16;
  static const double sizeSm = 14;
  static const double sizeXs = 13;
  static const double size2xs = 11;

  static const double leadingTight = 1.15;
  static const double leadingSnug = 1.3;
  static const double leadingNormal = 1.5;

  static const double trackingTight = -0.02 * 16; // applied as letterSpacing px
  static const double trackingCaps = 0.08 * 11;

  /// Material [TextTheme] mapped onto the SINTDT scale.
  static TextTheme textTheme(Brightness brightness) {
    final primary = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.ink50;
    final secondary = brightness == Brightness.light
        ? AppColors.textSecondary
        : AppColors.ink300;

    TextStyle sans(double size, FontWeight weight,
            {double height = leadingNormal, double? spacing, Color? color}) =>
        TextStyle(
          fontFamily: fontSans,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color ?? primary,
        );

    return TextTheme(
      displayLarge:
          sans(display, bold, height: leadingTight, spacing: trackingTight),
      headlineLarge:
          sans(h1, bold, height: leadingSnug, spacing: trackingTight),
      headlineMedium: sans(h2, bold, height: leadingSnug),
      titleLarge: sans(h3, bold, height: leadingSnug),
      titleMedium: sans(title, bold, height: leadingSnug),
      bodyLarge: sans(body, regular),
      bodyMedium: sans(sizeSm, regular, color: secondary),
      bodySmall: sans(sizeXs, regular, color: secondary),
      labelLarge: sans(title, bold), // buttons
      labelMedium: sans(sizeXs, semibold, color: secondary),
      labelSmall: sans(size2xs, semibold,
          height: leadingNormal, spacing: trackingCaps, color: secondary),
    );
  }

  /// Mono style for durations / counts (e.g. "~15m", "55m / 55m").
  static TextStyle mono(
          {double size = sizeXs,
          FontWeight weight = medium,
          Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontFamily: fontMono,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -0.13,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_typography_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/tokens/app_typography.dart test/design/app_typography_test.dart
git commit -m "feat(design): typography tokens + TextTheme"
```

---

### Task 7: Icon tokens + tokens barrel

**Files:**
- Create: `lib/core/design/tokens/app_icons.dart`, `lib/core/design/tokens/tokens.dart`
- Test: `test/design/app_icons_test.dart`

**Interfaces:**
- Consumes: `package:material_symbols_icons/symbols.dart`.
- Produces: `AppIcons` with the curated product glyph set as `IconData` consts (`checklist`, `add`, `addCircle`, `check`, `sun`, `eventRepeat`, `cloudOff`, `settings`, `mood`, `expandMore`, `close`, `info`, `favorite`, `error`, `delete`, plus category glyphs `countertops`, `laundry`, `skillet`, `bathtub`, `weekend`, `cart`). `tokens.dart` re-exports all token files.

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_icons_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';

void main() {
  test('curated glyphs map to Material Symbols Rounded', () {
    expect(AppIcons.checklist, Symbols.checklist_rounded);
    expect(AppIcons.add, Symbols.add_rounded);
    expect(AppIcons.eventRepeat, Symbols.event_repeat_rounded);
    expect(AppIcons.cloudOff, Symbols.cloud_off_rounded);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_icons_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/tokens/app_icons.dart
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Curated Material Symbols (Rounded) used across the product. Centralised so
/// product code references intent (`AppIcons.add`) not the icon font directly.
abstract final class AppIcons {
  static const IconData checklist = Symbols.checklist_rounded;
  static const IconData add = Symbols.add_rounded;
  static const IconData addCircle = Symbols.add_circle_rounded;
  static const IconData check = Symbols.check_rounded;
  static const IconData sun = Symbols.wb_sunny_rounded;
  static const IconData eventRepeat = Symbols.event_repeat_rounded;
  static const IconData cloudOff = Symbols.cloud_off_rounded;
  static const IconData settings = Symbols.settings_rounded;
  static const IconData mood = Symbols.sentiment_very_satisfied_rounded;
  static const IconData expandMore = Symbols.expand_more_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData info = Symbols.info_rounded;
  static const IconData favorite = Symbols.favorite_rounded;
  static const IconData error = Symbols.error_rounded;
  static const IconData delete = Symbols.delete_rounded;

  // Category / themed-day glyphs.
  static const IconData countertops = Symbols.countertops_rounded;
  static const IconData laundry = Symbols.local_laundry_service_rounded;
  static const IconData skillet = Symbols.skillet_rounded;
  static const IconData bathtub = Symbols.bathtub_rounded;
  static const IconData weekend = Symbols.weekend_rounded;
  static const IconData cart = Symbols.shopping_cart_rounded;
}
```

```dart
// lib/core/design/tokens/tokens.dart
export 'app_colors.dart';
export 'app_icons.dart';
export 'app_motion.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_typography.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_icons_test.dart`
Expected: PASS. (If a `Symbols.*_rounded` name differs in the installed package version, adjust to the package's actual constant — confirm with the package's `symbols.dart`.)

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/tokens/app_icons.dart lib/core/design/tokens/tokens.dart test/design/app_icons_test.dart
git commit -m "feat(design): icon tokens + tokens barrel"
```

---

### Task 8: Rebuild AppTheme (light + dark)

**Files:**
- Modify: `lib/app/theme.dart`
- Modify: `lib/app/app.dart` (set `themeMode: ThemeMode.system`)
- Test: `test/design/theme_test.dart`

**Interfaces:**
- Consumes: token classes via `lib/core/design/tokens/tokens.dart`.
- Produces: `AppTheme.light()` / `AppTheme.dark()` returning themed `ThemeData` with Nunito `TextTheme`, brand primary, ink50 (light) scaffold background.

- [ ] **Step 1: Write the failing test**

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/theme_test.dart`
Expected: FAIL — assertions don't match the current `fromSeed` theme.

- [ ] **Step 3: Write the implementation**

```dart
// lib/app/theme.dart
import 'package:flutter/material.dart';

import '../core/design/tokens/tokens.dart';

/// App theming, built from the SINTDT design tokens (not `fromSeed`).
/// Light is design-authoritative; dark is a best-effort adaptation pending
/// dark tokens in the design system.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brand,
      onPrimary: AppColors.textOnBrand,
      primaryContainer: AppColors.brandSoft,
      onPrimaryContainer: AppColors.textBrand,
      secondary: AppColors.today,
      onSecondary: AppColors.ink900,
      tertiary: AppColors.reschedule,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.borderDefault,
    );
    return _build(scheme, AppColors.surfacePage);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.blue400,
      onPrimary: AppColors.ink900,
      primaryContainer: AppColors.blue800,
      onPrimaryContainer: AppColors.blue100,
      secondary: AppColors.sun400,
      onSecondary: AppColors.ink900,
      tertiary: AppColors.coral400,
      onTertiary: AppColors.ink900,
      error: AppColors.red400,
      onError: AppColors.ink900,
      surface: AppColors.ink800,
      onSurface: AppColors.ink50,
      onSurfaceVariant: AppColors.ink300,
      outline: AppColors.ink600,
      outlineVariant: AppColors.ink700,
    );
    return _build(scheme, AppColors.ink900);
  }

  static ThemeData _build(ColorScheme scheme, Color background) {
    final isLight = scheme.brightness == Brightness.light;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      textTheme: AppTypography.textTheme(scheme.brightness),
      fontFamily: AppTypography.fontSans,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.textTheme(scheme.brightness)
            .headlineMedium!
            .copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.ink900 : AppColors.ink700,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.fontSans,
          fontWeight: AppTypography.semibold,
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
```

- [ ] **Step 4: Set `themeMode` explicitly in `app.dart`**

In `lib/app/app.dart`, add `themeMode: ThemeMode.system,` to the `MaterialApp.router(...)` call (after `darkTheme:`).

- [ ] **Step 5: Run tests to verify pass**

Run: `flutter test test/design/theme_test.dart && flutter analyze`
Expected: PASS; analyze clean.

- [ ] **Step 6: Commit**

```bash
git add lib/app/theme.dart lib/app/app.dart test/design/theme_test.dart
git commit -m "feat(design): rebuild AppTheme from tokens (light + dark)"
```

---

> Tasks 9–20 build the widget library. Each widget reads tokens directly, gets a behavioural widget test, and is exported from `widgets.dart` (created in Task 21). Build order respects dependencies: Badge & Checkbox before TaskItem; Card, Chip, Button before the reskin.

### Task 9: AppBadge

**Files:**
- Create: `lib/core/design/widgets/app_badge.dart`
- Test: `test/design/app_badge_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `AppRadii`.
- Produces: `enum AppBadgeTone { done, today, reschedule, brand }`; `class AppBadge` with `String label`, `AppBadgeTone? tone`, `bool soft = true`.

*Design (`Badge.jsx`): height 24, padding 0×9, radius pill, mono font, size xs(13), weight medium(600). soft+tone → fill = lerp(white,toneColor,0.14), text = toneColor; soft+no tone → fill ink100, text ink600; solid → fill toneColor, text white.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_badge_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_badge_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_badge.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppBadgeTone { done, today, reschedule, brand }

/// Mono duration / count pill (e.g. "~15m", "55m budget").
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone, this.soft = true});

  final String label;
  final AppBadgeTone? tone;
  final bool soft;

  static const _toneColors = {
    AppBadgeTone.done: AppColors.done,
    AppBadgeTone.today: AppColors.today,
    AppBadgeTone.reschedule: AppColors.reschedule,
    AppBadgeTone.brand: AppColors.brand,
  };

  @override
  Widget build(BuildContext context) {
    final toneColor = tone == null ? null : _toneColors[tone];
    final Color background;
    final Color foreground;
    if (!soft) {
      background = toneColor ?? AppColors.ink500;
      foreground = AppColors.white;
    } else if (toneColor != null) {
      background = Color.lerp(AppColors.white, toneColor, 0.14)!;
      foreground = toneColor;
    } else {
      background = AppColors.ink100;
      foreground = AppColors.ink600;
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppTypography.mono(
          size: AppTypography.sizeXs,
          weight: AppTypography.medium,
          color: foreground,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_badge_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_badge.dart test/design/app_badge_test.dart
git commit -m "feat(design): AppBadge"
```

---

### Task 10: AppCheckbox

**Files:**
- Create: `lib/core/design/widgets/app_checkbox.dart`
- Test: `test/design/app_checkbox_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppIcons`, `AppMotion`.
- Produces: `class AppCheckbox` with `bool value`, `ValueChanged<bool>? onChanged`, `double size = 26`, `Color? color`.

*Design (`Checkbox.jsx`): round; border 2px (checked→color, else ink300); fill checked→color else white; white tick scaled 0→1 with spring over `normal`. Default color = done green. `onChanged(!value)`, swallow the tap.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_checkbox_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_checkbox.dart';

void main() {
  testWidgets('tapping toggles and reports the next value', (tester) async {
    bool? next;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppCheckbox(value: false, onChanged: (v) => next = v),
        ),
      ),
    ));
    await tester.tap(find.byType(AppCheckbox));
    expect(next, isTrue);
  });

  testWidgets('disabled (null onChanged) does nothing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: AppCheckbox(value: false))),
    ));
    await tester.tap(find.byType(AppCheckbox));
    // No exception, nothing to assert beyond not throwing.
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_checkbox_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_checkbox.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Round, friendly tick-box — the core gesture of completing a chore.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 26,
    this.color,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? AppColors.done;
    final enabled = onChanged != null;
    return Semantics(
      checked: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.normal),
            curve: AppMotion.spring,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? fill : AppColors.white,
              border: Border.all(
                color: value ? fill : AppColors.borderStrong,
                width: 2,
              ),
            ),
            child: AnimatedScale(
              duration: AppMotion.of(context, AppMotion.normal),
              curve: AppMotion.spring,
              scale: value ? 1 : 0,
              child: Icon(AppIcons.check,
                  size: size * 0.66, color: AppColors.white),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_checkbox_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_checkbox.dart test/design/app_checkbox_test.dart
git commit -m "feat(design): AppCheckbox"
```

---

### Task 11: AppCard

**Files:**
- Create: `lib/core/design/widgets/app_card.dart`
- Test: `test/design/app_card_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppRadii`, `AppShadows`, `AppSpacing`, `AppMotion`.
- Produces: `class AppCard` with `Widget child`, `EdgeInsetsGeometry? padding` (default all `AppSpacing.x5`), `bool interactive = false`, `VoidCallback? onTap`.

*Design (`Card.jsx`): white, radius xl(24), shadow-card, padding space-5; interactive lifts to shadow-raised + translateY(-2) on hover over `normal`/soft.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_card.dart';

void main() {
  testWidgets('renders child and fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppCard(
          interactive: true,
          onTap: () => taps++,
          child: const Text('hello'),
        ),
      ),
    ));
    expect(find.text('hello'), findsOneWidget);
    await tester.tap(find.text('hello'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_card_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_card.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Soft, rounded white surface container. `interactive` lifts on hover.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.interactive = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool interactive;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final lifted = widget.interactive && _hovering;
    final card = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.normal),
      curve: AppMotion.soft,
      transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: lifted ? AppShadows.raised : AppShadows.card,
      ),
      child: widget.child,
    );

    if (!widget.interactive && widget.onTap == null) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_card.dart test/design/app_card_test.dart
git commit -m "feat(design): AppCard"
```

---

### Task 12: AppChip

**Files:**
- Create: `lib/core/design/widgets/app_chip.dart`
- Test: `test/design/app_chip_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `AppRadii`.
- Produces: `enum AppChipTone { neutral, brand, today, done, reschedule }`; `class AppChip` with `String label`, `AppChipTone tone = AppChipTone.neutral`, `IconData? icon`, `bool selected = false`, `bool selectable = false`, `VoidCallback? onTap`.

*Design (`Chip.jsx`): height 30, padding 0×12, radius pill, font sans xs(13) bold; tone fills: neutral ink100/ink600, brand blue50/blue600, today sun200/sun600, done green200/green600, reschedule coral200/coral600. When `selectable && !selected`: transparent bg, 1.5px border-default, text muted; else filled tone. icon size 15, gap 6.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_chip.dart';

void main() {
  testWidgets('renders label and fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppChip(
            label: 'Kitchen',
            tone: AppChipTone.today,
            onTap: () => taps++,
          ),
        ),
      ),
    ));
    expect(find.text('Kitchen'), findsOneWidget);
    await tester.tap(find.text('Kitchen'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_chip_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_chip.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppChipTone { neutral, brand, today, done, reschedule }

/// Small rounded pill for categories, themed days and filters.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.tone = AppChipTone.neutral,
    this.icon,
    this.selected = false,
    this.selectable = false,
    this.onTap,
  });

  final String label;
  final AppChipTone tone;
  final IconData? icon;
  final bool selected;
  final bool selectable;
  final VoidCallback? onTap;

  static const _fills = {
    AppChipTone.neutral: (AppColors.ink100, AppColors.ink600),
    AppChipTone.brand: (AppColors.brandSoft, AppColors.textBrand),
    AppChipTone.today: (AppColors.todaySoft, AppColors.sun600),
    AppChipTone.done: (AppColors.doneSoft, AppColors.green600),
    AppChipTone.reschedule: (AppColors.rescheduleSoft, AppColors.coral600),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _fills[tone]!;
    final isFilled = selectable ? selected : true;
    final showBorder = selectable && !selected;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isFilled ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: showBorder ? AppColors.borderDefault : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15, color: isFilled ? fg : AppColors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontSans,
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.bold,
                color: isFilled ? fg : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_chip_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_chip.dart test/design/app_chip_test.dart
git commit -m "feat(design): AppChip"
```

---

### Task 13: AppButton

**Files:**
- Create: `lib/core/design/widgets/app_button.dart`
- Test: `test/design/app_button_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `AppRadii`, `AppShadows`, `AppMotion`.
- Produces: `enum AppButtonVariant { primary, tonal, ghost, danger }`; `enum AppButtonSize { sm, md, lg }`; `class AppButton` with `String label`, `VoidCallback? onPressed` (null = disabled), `AppButtonVariant variant = primary`, `AppButtonSize size = md`, `bool pill = false`, `bool block = false`, `IconData? icon`, `IconData? iconRight`.

*Design (`Button.jsx`): sizes sm{h36,pad14,font sm(14),icon16,gap6} / md{h46,pad20,font title(17),icon18,gap8} / lg{h54,pad26,font h3(20),icon20,gap10}; weight bold, letterSpacing tight, radius pill?pill:md(14). primary→brand bg/white fg/shadow-brand; tonal→blue50 bg/blue600 fg; ghost→transparent bg/ink600 fg/1px border-default; danger→red500 bg/white fg/red shadow. disabled opacity 0.45. Press scales to 0.96 (spring).*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_button.dart';

void main() {
  testWidgets('renders label and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppButton(label: 'Add task', onPressed: () => taps++),
        ),
      ),
    ));
    expect(find.text('Add task'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('disabled when onPressed is null', (tester) async {
    var taps = 0;
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: AppButton(label: 'Nope'))),
    ));
    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_button_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_button.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppButtonVariant { primary, tonal, ghost, danger }

enum AppButtonSize { sm, md, lg }

class _SizeSpec {
  const _SizeSpec(this.height, this.padX, this.font, this.icon, this.gap);
  final double height;
  final double padX;
  final double font;
  final double icon;
  final double gap;
}

class _VariantSpec {
  const _VariantSpec(this.bg, this.fg, this.shadow, this.border);
  final Color bg;
  final Color fg;
  final List<BoxShadow> shadow;
  final Color? border;
}

/// Friendly, rounded, soft-shadowed call-to-action button.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.pill = false,
    this.block = false,
    this.icon,
    this.iconRight,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool pill;
  final bool block;
  final IconData? icon;
  final IconData? iconRight;

  static const _sizes = {
    AppButtonSize.sm: _SizeSpec(36, 14, AppTypography.sizeSm, 16, 6),
    AppButtonSize.md: _SizeSpec(46, 20, AppTypography.title, 18, 8),
    AppButtonSize.lg: _SizeSpec(54, 26, AppTypography.h3, 20, 10),
  };

  static const _danger = [
    BoxShadow(color: Color(0x47E5484D), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const _variants = {
    AppButtonVariant.primary: _VariantSpec(
        AppColors.brand, AppColors.textOnBrand, AppShadows.brand, null),
    AppButtonVariant.tonal: _VariantSpec(
        AppColors.brandSoft, AppColors.textBrand, [], null),
    AppButtonVariant.ghost: _VariantSpec(Colors.transparent,
        AppColors.textSecondary, [], AppColors.borderDefault),
    AppButtonVariant.danger:
        _VariantSpec(AppColors.error, AppColors.white, _danger, null),
  };

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = AppButton._sizes[widget.size]!;
    final v = AppButton._variants[widget.variant]!;
    final enabled = widget.onPressed != null;

    final content = Row(
      mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: s.icon, color: v.fg),
          SizedBox(width: s.gap),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: AppTypography.fontSans,
            fontSize: s.font,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.34,
            color: v.fg,
          ),
        ),
        if (widget.iconRight != null) ...[
          SizedBox(width: s.gap),
          Icon(widget.iconRight, size: s.icon, color: v.fg),
        ],
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.spring,
          child: Container(
            height: s.height,
            width: widget.block ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: s.padX),
            decoration: BoxDecoration(
              color: v.bg,
              borderRadius:
                  BorderRadius.circular(widget.pill ? AppRadii.pill : AppRadii.md),
              boxShadow: enabled ? v.shadow : const [],
              border: v.border == null
                  ? null
                  : Border.all(color: v.border!, width: 1),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_button_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_button.dart test/design/app_button_test.dart
git commit -m "feat(design): AppButton"
```

---

### Task 14: AppIconButton

**Files:**
- Create: `lib/core/design/widgets/app_icon_button.dart`
- Test: `test/design/app_icon_button_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppRadii`, `AppMotion`.
- Produces: `enum AppIconButtonTone { normal, brand, onBrand }`; `class AppIconButton` with `IconData icon`, `VoidCallback? onPressed`, `double size = 44`, `AppIconButtonTone tone = normal`, `String? tooltip`.

*Design (`IconButton.jsx`): round (radius pill), size 44; icon size round(size*0.5); tones: normal→ink600 fg/transparent bg/ink100 hover; brand→brand fg/blue50 bg/blue100 hover; onBrand→white fg/white@16% bg/white@28% hover. Press scale 0.9.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_icon_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';
import 'package:snitd/core/design/widgets/app_icon_button.dart';

void main() {
  testWidgets('fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppIconButton(
          icon: AppIcons.settings,
          tooltip: 'Settings',
          onPressed: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(AppIconButton));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_icon_button_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_icon_button.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppIconButtonTone { normal, brand, onBrand }

/// Round icon control for app-bar actions and inline affordances.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.tone = AppIconButtonTone.normal,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final AppIconButtonTone tone;
  final String? tooltip;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _pressed = false;
  bool _hovering = false;

  ({Color fg, Color bg, Color hover}) get _spec => switch (widget.tone) {
        AppIconButtonTone.normal => (
            fg: AppColors.textSecondary,
            bg: Colors.transparent,
            hover: AppColors.ink100,
          ),
        AppIconButtonTone.brand => (
            fg: AppColors.brand,
            bg: AppColors.brandSoft,
            hover: AppColors.brandSoftHover,
          ),
        AppIconButtonTone.onBrand => (
            fg: AppColors.white,
            bg: AppColors.white.withValues(alpha: 0.16),
            hover: AppColors.white.withValues(alpha: 0.28),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final enabled = widget.onPressed != null;
    final button = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.spring,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.soft,
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovering ? spec.hover : spec.bg,
            ),
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Icon(widget.icon,
                  size: (widget.size * 0.5).roundToDouble(), color: spec.fg),
            ),
          ),
        ),
      ),
    );
    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_icon_button_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_icon_button.dart test/design/app_icon_button_test.dart
git commit -m "feat(design): AppIconButton"
```

---

### Task 15: AppSwitch

**Files:**
- Create: `lib/core/design/widgets/app_switch.dart`
- Test: `test/design/app_switch_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppShadows`, `AppMotion`.
- Produces: `class AppSwitch` with `bool value`, `ValueChanged<bool>? onChanged`.

*Design (`Switch.jsx`): track W52×H30 radius pill, bg brand(on)/ink300(off); white knob 24 with shadow-sm, slides left 3 → 25 with spring; bg transitions over `normal`/soft.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_switch_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_switch.dart';

void main() {
  testWidgets('tapping reports the toggled value', (tester) async {
    bool? next;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppSwitch(value: false, onChanged: (v) => next = v),
        ),
      ),
    ));
    await tester.tap(find.byType(AppSwitch));
    expect(next, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_switch_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_switch.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Pill toggle switch for settings (e.g. Profanity mode).
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _w = 52;
  static const double _h = 30;
  static const double _knob = 24;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.normal),
            curve: AppMotion.soft,
            width: _w,
            height: _h,
            decoration: BoxDecoration(
              color: value ? AppColors.brand : AppColors.ink300,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: AnimatedAlign(
              duration: AppMotion.of(context, AppMotion.normal),
              curve: AppMotion.spring,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: _knob,
                  height: _knob,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    boxShadow: AppShadows.sm,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_switch_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_switch.dart test/design/app_switch_test.dart
git commit -m "feat(design): AppSwitch"
```

---

### Task 16: AppSegmentedControl

**Files:**
- Create: `lib/core/design/widgets/app_segmented_control.dart`
- Test: `test/design/app_segmented_control_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `AppRadii`, `AppShadows`, `AppMotion`.
- Produces: `class AppSegment<T>` (`{T value, String label}`); `class AppSegmentedControl<T>` with `List<AppSegment<T>> segments`, `T value`, `ValueChanged<T> onChanged`, `bool small = false`.

*Design (`SegmentedControl.jsx`): track ink100 radius pill padding 3, height 40 (md) / 34 (sm); selected segment → white bg + shadow-sm + text-primary; unselected → transparent + text-muted; font sans bold sm(14)/xs(13), padding 0×16.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_segmented_control_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_segmented_control.dart';

void main() {
  testWidgets('tapping a segment reports its value', (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppSegmentedControl<String>(
            value: 'week',
            onChanged: (v) => picked = v,
            segments: const [
              AppSegment(value: 'week', label: 'Week'),
              AppSegment(value: 'month', label: 'Month'),
            ],
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Month'));
    expect(picked, 'month');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_segmented_control_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_segmented_control.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

class AppSegment<T> {
  const AppSegment({required this.value, required this.label});
  final T value;
  final String label;
}

/// Pill-tracked tab switch for periods & filters (Week / Month / Year).
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.small = false,
  });

  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final height = small ? 34.0 : 40.0;
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.ink100,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final seg in segments)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(seg.value),
              child: AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.fast),
                curve: AppMotion.soft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: seg.value == value
                      ? AppColors.surfaceCard
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: seg.value == value ? AppShadows.sm : const [],
                ),
                child: Text(
                  seg.label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontSans,
                    fontSize:
                        small ? AppTypography.sizeXs : AppTypography.sizeSm,
                    fontWeight: AppTypography.bold,
                    color: seg.value == value
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_segmented_control_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_segmented_control.dart test/design/app_segmented_control_test.dart
git commit -m "feat(design): AppSegmentedControl"
```

---

### Task 17: AppProgressMeter

**Files:**
- Create: `lib/core/design/widgets/app_progress_meter.dart`
- Test: `test/design/app_progress_meter_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `AppRadii`, `AppMotion`.
- Produces: `class AppProgressMeter` with `double value`, `double max`, `String? label`, `bool showValue = true`, `String unit = 'm'`, `double height = 10`. The fill `AnimatedContainer` carries `const Key('appProgressMeterFill')`.

*Design (`ProgressMeter.jsx`): pct clamped 0–100; fill brand normally, **coral when value > max**; track ink200; rounded; label sans sm bold text-secondary; value mono xs medium (coral600 when over); width animates over `slow`/easeOut.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_progress_meter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_colors.dart';
import 'package:snitd/core/design/widgets/app_progress_meter.dart';

BoxDecoration _fillDecoration(WidgetTester tester) {
  final c = tester.widget<AnimatedContainer>(
      find.byKey(const Key('appProgressMeterFill')));
  return c.decoration! as BoxDecoration;
}

void main() {
  testWidgets('fills brand under budget', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AppProgressMeter(value: 30, max: 55)),
    ));
    await tester.pumpAndSettle();
    expect(_fillDecoration(tester).color, AppColors.brand);
  });

  testWidgets('tips to coral when over budget', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AppProgressMeter(value: 70, max: 55)),
    ));
    await tester.pumpAndSettle();
    expect(_fillDecoration(tester).color, AppColors.reschedule);
    expect(find.text('70m / 55m'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_progress_meter_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_progress_meter.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Daily-load bar against a forgiving budget. Fills brand-blue, tips to coral
/// when over — a gentle nudge, never an alarm.
class AppProgressMeter extends StatelessWidget {
  const AppProgressMeter({
    super.key,
    required this.value,
    required this.max,
    this.label,
    this.showValue = true,
    this.unit = 'm',
    this.height = 10,
  });

  final double value;
  final double max;
  final String? label;
  final bool showValue;
  final String unit;
  final double height;

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    final factor = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final over = value > max;
    final fill = over ? AppColors.reschedule : AppColors.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showValue)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (label != null)
                  Text(label!,
                      style: TextStyle(
                        fontFamily: AppTypography.fontSans,
                        fontSize: AppTypography.sizeSm,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textSecondary,
                      ))
                else
                  const SizedBox.shrink(),
                if (showValue)
                  Text('${_fmt(value)}$unit / ${_fmt(max)}$unit',
                      style: AppTypography.mono(
                        size: AppTypography.sizeXs,
                        color: over
                            ? AppColors.coral600
                            : AppColors.textMuted,
                      )),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            height: height,
            color: AppColors.ink200,
            child: Align(
              alignment: Alignment.centerLeft,
              child: LayoutBuilder(
                builder: (context, constraints) => AnimatedContainer(
                  key: const Key('appProgressMeterFill'),
                  duration: AppMotion.of(context, AppMotion.slow),
                  curve: AppMotion.easeOut,
                  width: constraints.maxWidth * factor,
                  height: height,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_progress_meter_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_progress_meter.dart test/design/app_progress_meter_test.dart
git commit -m "feat(design): AppProgressMeter"
```

---

### Task 18: AppAvatar

**Files:**
- Create: `lib/core/design/widgets/app_avatar.dart`
- Test: `test/design/app_avatar_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`.
- Produces: `class AppAvatar` with `String name`, `String? imageUrl`, `double size = 40`, `Color? color`.

*Design (`Avatar.jsx`): initials = first letter of up to 2 words, uppercase, fallback '?'; deterministic tint picked from a 4-entry palette by name hash; `color` forces solid bg + white text; circle; font sans bold size round(size*0.4).*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_avatar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_avatar.dart';

void main() {
  testWidgets('derives up to two uppercase initials', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: AppAvatar(name: 'Richard Brown'))),
    ));
    expect(find.text('RB'), findsOneWidget);
  });

  testWidgets('falls back to ? for an empty name', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: AppAvatar(name: ''))),
    ));
    expect(find.text('?'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_avatar_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_avatar.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Round identity chip with initials or an image, for household members.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.color,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final Color? color;

  static const _palette = [
    (AppColors.blue100, AppColors.blue700),
    (AppColors.todaySoft, AppColors.sun600),
    (AppColors.rescheduleSoft, AppColors.coral600),
    (AppColors.doneSoft, AppColors.green600),
  ];

  String get _initials {
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0]).join().toUpperCase();
  }

  (Color, Color) get _tint {
    if (color != null) return (color!, AppColors.white);
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _palette[h % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _tint;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? Image.network(imageUrl!, fit: BoxFit.cover)
            : Container(
                color: bg,
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontFamily: AppTypography.fontSans,
                    fontWeight: AppTypography.bold,
                    fontSize: (size * 0.4).roundToDouble(),
                    color: fg,
                  ),
                ),
              ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_avatar_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_avatar.dart test/design/app_avatar_test.dart
git commit -m "feat(design): AppAvatar"
```

---

### Task 19: AppBanner

**Files:**
- Create: `lib/core/design/widgets/app_banner.dart`
- Test: `test/design/app_banner_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppIcons`, `AppTypography`, `AppRadii`, `AppSpacing`.
- Produces: `enum AppBannerTone { info, offline, gentle, error }`; `class AppBanner` with `String message`, `AppBannerTone tone = info`, `IconData? icon`, `Widget? action`.

*Design (`Banner.jsx`): padding 12×14, radius lg(18), gap space-3(12), icon size 20; text sans sm semibold leading snug. info→blue50/blue600/info; offline→ink100/ink600/cloud_off; gentle→coral200/coral600/favorite; error→lerp(white,red500,0.14)/red600/error.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_banner_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_banner.dart';

void main() {
  testWidgets('renders its message and a leading icon', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AppBanner(
          message: 'You are offline',
          tone: AppBannerTone.offline,
        ),
      ),
    ));
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_banner_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_banner.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppBannerTone { info, offline, gentle, error }

/// Soft inline notice strip (offline state, forgiving nudges, info).
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.tone = AppBannerTone.info,
    this.icon,
    this.action,
  });

  final String message;
  final AppBannerTone tone;
  final IconData? icon;
  final Widget? action;

  ({Color bg, Color fg, IconData icon}) get _spec => switch (tone) {
        AppBannerTone.info => (
            bg: AppColors.brandSoft,
            fg: AppColors.textBrand,
            icon: AppIcons.info,
          ),
        AppBannerTone.offline => (
            bg: AppColors.ink100,
            fg: AppColors.ink600,
            icon: AppIcons.cloudOff,
          ),
        AppBannerTone.gentle => (
            bg: AppColors.rescheduleSoft,
            fg: AppColors.coral600,
            icon: AppIcons.favorite,
          ),
        AppBannerTone.error => (
            bg: Color.lerp(AppColors.white, AppColors.error, 0.14)!,
            fg: AppColors.red600,
            icon: AppIcons.error,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Icon(icon ?? spec.icon, size: 20, color: spec.fg),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AppTypography.fontSans,
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.semibold,
                height: AppTypography.leadingSnug,
                color: spec.fg,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: AppSpacing.x3), action!],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_banner_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_banner.dart test/design/app_banner_test.dart
git commit -m "feat(design): AppBanner"
```

---

### Task 20: AppBrandMark

**Files:**
- Create: `lib/core/design/widgets/app_brand_mark.dart`
- Test: `test/design/app_brand_mark_test.dart`

**Interfaces:**
- Consumes: `AppColors`.
- Produces: `class AppBrandMark extends StatelessWidget` with `double size = 96`.

*Design (`assets/sintdt-mark.svg`, viewBox 96): rounded tile rx26 with linear gradient blue400→blue600 from (14,8)→(82,88); amber sun at (74,22) — r11 at 28% opacity + r7 solid (sun500); white tick path `M26,49.5 l13,13 L70,31.5`, stroke width 7.5, round caps. Canvas scales by size/96.*

- [ ] **Step 1: Write the failing test**

```dart
// test/design/app_brand_mark_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_brand_mark.dart';

void main() {
  testWidgets('paints at the requested size', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: AppBrandMark(size: 72))),
    ));
    expect(find.byType(AppBrandMark), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    final size = tester.getSize(find.byType(AppBrandMark));
    expect(size, const Size(72, 72));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design/app_brand_mark_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/design/widgets/app_brand_mark.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// The SINTDT app mark: a rounded blue tile with a sun and a white tick.
/// Drawn with a [CustomPainter] (no SVG dependency); scales from a 96px design.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _MarkPainter()));
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 96.0;
    canvas.scale(s, s);

    // Tile with the brand gradient.
    final tile = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 96, 96),
      const Radius.circular(26),
    );
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.blue400, AppColors.blue600],
    ).createShader(const Rect.fromLTWH(14, 8, 68, 80));
    canvas.drawRRect(tile, Paint()..shader = gradient);

    // Sun: soft halo + solid core.
    canvas.drawCircle(const Offset(74, 22), 11,
        Paint()..color = AppColors.sun500.withValues(alpha: 0.28));
    canvas.drawCircle(
        const Offset(74, 22), 7, Paint()..color = AppColors.sun500);

    // Tick.
    final tick = Path()
      ..moveTo(26, 49.5)
      ..relativeLineTo(13, 13)
      ..lineTo(70, 31.5);
    canvas.drawPath(
      tick,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/design/app_brand_mark_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design/widgets/app_brand_mark.dart test/design/app_brand_mark_test.dart
git commit -m "feat(design): AppBrandMark"
```

---

### Task 21: Widget + design barrels

**Files:**
- Create: `lib/core/design/widgets/widgets.dart`, `lib/core/design/design.dart`

**Interfaces:**
- Produces: `widgets.dart` (exports all 12 widget files); `design.dart` (exports `tokens/tokens.dart` + `widgets/widgets.dart`).

- [ ] **Step 1: Create the barrels**

```dart
// lib/core/design/widgets/widgets.dart
export 'app_avatar.dart';
export 'app_badge.dart';
export 'app_banner.dart';
export 'app_brand_mark.dart';
export 'app_button.dart';
export 'app_card.dart';
export 'app_checkbox.dart';
export 'app_chip.dart';
export 'app_icon_button.dart';
export 'app_progress_meter.dart';
export 'app_segmented_control.dart';
export 'app_switch.dart';
```

```dart
// lib/core/design/design.dart
export 'tokens/tokens.dart';
export 'widgets/widgets.dart';
```

- [ ] **Step 2: Verify analysis is clean**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/design/widgets/widgets.dart lib/core/design/design.dart
git commit -m "feat(design): widget + design barrels"
```

---

### Task 22: AppTaskItem (the signature row)

**Files:**
- Create: `lib/features/tasks/presentation/widgets/task_item.dart`
- Test: `test/features/tasks/task_item_test.dart`

**Interfaces:**
- Consumes: `AppCheckbox`, `AppBadge` (+ tokens).
- Produces: `class AppTaskItem` with `String title`, `int? minutes`, `String? category`, `bool done = false`, `String? movedFrom`, `ValueChanged<bool>? onToggle`.

*Design (`TaskItem.jsx`): Row — round Checkbox, gap space-3; Expanded column: title sans title(17) bold ink900, line-through (ink300) + container opacity 0.62 when done, ellipsis; sub-row gap 8 marginTop 3: category sans xs semibold ink500, and (if movedFrom) coral600 row [event_repeat 14 + "moved from <day>"]; trailing AppBadge(tone done?done:none) "~Nm". Container: white, radius lg(18), shadow-card, padding 14×16. Never red.*

- [ ] **Step 1: Write the failing test**

```dart
// test/features/tasks/task_item_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_checkbox.dart';
import 'package:snitd/features/tasks/presentation/widgets/task_item.dart';

void main() {
  testWidgets('renders title, estimate badge and moved-from note',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AppTaskItem(
          title: 'Clean toilets',
          minutes: 5,
          category: 'Bathrooms & Mail',
          movedFrom: 'Tuesday',
        ),
      ),
    ));
    expect(find.text('Clean toilets'), findsOneWidget);
    expect(find.text('~5m'), findsOneWidget);
    expect(find.textContaining('moved from Tuesday'), findsOneWidget);
  });

  testWidgets('ticking calls onToggle with the next value', (tester) async {
    bool? next;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppTaskItem(
          title: 'Wash bedding',
          minutes: 10,
          onToggle: (v) => next = v,
        ),
      ),
    ));
    await tester.tap(find.byType(AppCheckbox));
    expect(next, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/tasks/task_item_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/tasks/presentation/widgets/task_item.dart
import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// The signature SINTDT chore row: round tick, time estimate, category, and —
/// when the forgiving scheduler moved it — a gentle coral "moved from…" note.
/// Completed rows soften and strike through; nothing is ever shamed in red.
class AppTaskItem extends StatelessWidget {
  const AppTaskItem({
    super.key,
    required this.title,
    this.minutes,
    this.category,
    this.done = false,
    this.movedFrom,
    this.onToggle,
  });

  final String title;
  final int? minutes;
  final String? category;
  final bool done;
  final String? movedFrom;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppMotion.of(context, AppMotion.normal),
      curve: AppMotion.soft,
      opacity: done ? 0.62 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            AppCheckbox(
              value: done,
              onChanged: onToggle == null ? null : (v) => onToggle!(v),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontSans,
                      fontSize: AppTypography.title,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                      decoration:
                          done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: AppColors.ink300,
                    ),
                  ),
                  if (category != null || movedFrom != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          if (category != null)
                            Text(
                              category!,
                              style: TextStyle(
                                fontFamily: AppTypography.fontSans,
                                fontSize: AppTypography.sizeXs,
                                fontWeight: AppTypography.semibold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          if (category != null && movedFrom != null)
                            const SizedBox(width: 8),
                          if (movedFrom != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(AppIcons.eventRepeat,
                                    size: 14, color: AppColors.coral600),
                                const SizedBox(width: 3),
                                Text(
                                  'moved from $movedFrom',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontSans,
                                    fontSize: AppTypography.sizeXs,
                                    fontWeight: AppTypography.semibold,
                                    color: AppColors.coral600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (minutes != null) ...[
              const SizedBox(width: AppSpacing.x2),
              AppBadge(
                label: '~${minutes}m',
                tone: done ? AppBadgeTone.done : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/tasks/task_item_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/presentation/widgets/task_item.dart test/features/tasks/task_item_test.dart
git commit -m "feat(tasks): AppTaskItem signature row"
```

---

### Task 23: Debug component gallery + route

**Files:**
- Create: `lib/core/design/gallery/gallery_screen.dart`
- Modify: `lib/app/router.dart` (add `Routes.gallery` + `GoRoute`)

**Interfaces:**
- Consumes: `design.dart`, `AppTaskItem`.
- Produces: `class GalleryScreen extends StatelessWidget`; `Routes.gallery = '/gallery'`.

- [ ] **Step 1: Add the route**

In `lib/app/router.dart`: add `static const gallery = '/gallery';` to `Routes`, import the gallery screen, and add a `GoRoute(path: Routes.gallery, builder: (context, state) => const GalleryScreen())` to the `routes:` list.

- [ ] **Step 2: Write the gallery screen**

```dart
// lib/core/design/gallery/gallery_screen.dart
import 'package:flutter/material.dart';

import '../../../features/tasks/presentation/widgets/task_item.dart';
import '../design.dart';

/// Debug-only showcase of the design system: tokens + every widget variant.
/// Linked from Settings in debug builds; useful as living documentation.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _switch = true;
  bool _check = false;
  String _segment = 'week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: [
          const _Section('Brand'),
          const Center(child: AppBrandMark(size: 88)),
          const _Section('Buttons'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            AppButton(label: 'Primary', onPressed: () {}),
            AppButton(
                label: 'Tonal',
                variant: AppButtonVariant.tonal,
                onPressed: () {}),
            AppButton(
                label: 'Ghost',
                variant: AppButtonVariant.ghost,
                onPressed: () {}),
            AppButton(
                label: 'Danger',
                variant: AppButtonVariant.danger,
                onPressed: () {}),
            AppButton(
                label: 'Add',
                icon: AppIcons.add,
                pill: true,
                onPressed: () {}),
            const AppButton(label: 'Disabled'),
          ]),
          const _Section('Icon buttons'),
          Row(children: [
            AppIconButton(icon: AppIcons.settings, onPressed: () {}),
            const SizedBox(width: 8),
            AppIconButton(
                icon: AppIcons.add,
                tone: AppIconButtonTone.brand,
                onPressed: () {}),
          ]),
          const _Section('Segmented control'),
          AppSegmentedControl<String>(
            value: _segment,
            onChanged: (v) => setState(() => _segment = v),
            segments: const [
              AppSegment(value: 'week', label: 'Week'),
              AppSegment(value: 'month', label: 'Month'),
              AppSegment(value: 'year', label: 'Year'),
            ],
          ),
          const _Section('Chips'),
          Wrap(spacing: 8, runSpacing: 8, children: const [
            AppChip(label: 'Neutral'),
            AppChip(label: 'Today', tone: AppChipTone.today),
            AppChip(label: 'Done', tone: AppChipTone.done),
            AppChip(label: 'Moved', tone: AppChipTone.reschedule),
          ]),
          const _Section('Badges'),
          Wrap(spacing: 8, runSpacing: 8, children: const [
            AppBadge(label: '~15m'),
            AppBadge(label: '55m', tone: AppBadgeTone.brand),
            AppBadge(label: 'done', tone: AppBadgeTone.done),
          ]),
          const _Section('Progress meter'),
          const AppProgressMeter(value: 30, max: 55, label: "Today's load"),
          const SizedBox(height: 12),
          const AppProgressMeter(value: 70, max: 55, label: 'Over budget'),
          const _Section('Avatars'),
          Row(children: const [
            AppAvatar(name: 'Richard Brown'),
            SizedBox(width: 8),
            AppAvatar(name: 'Sam Lee'),
          ]),
          const _Section('Banners'),
          const AppBanner(
              message: 'You are offline', tone: AppBannerTone.offline),
          const SizedBox(height: 8),
          const AppBanner(
              message: 'We moved 2 tasks to a quieter day',
              tone: AppBannerTone.gentle),
          const _Section('Switch / checkbox'),
          Row(children: [
            AppSwitch(value: _switch, onChanged: (v) => setState(() => _switch = v)),
            const SizedBox(width: 16),
            AppCheckbox(value: _check, onChanged: (v) => setState(() => _check = v)),
          ]),
          const _Section('Task items'),
          const AppTaskItem(
              title: 'Wash bedding',
              minutes: 10,
              category: 'Kitchen & Bedding'),
          const SizedBox(height: 8),
          const AppTaskItem(
              title: 'Clean toilets',
              minutes: 5,
              category: 'Bathrooms & Mail',
              movedFrom: 'Tuesday'),
          const SizedBox(height: 8),
          const AppTaskItem(title: 'Empty trash', minutes: 10, done: true),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );
}
```

- [ ] **Step 3: Verify it builds and analyses**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/core/design/gallery/gallery_screen.dart lib/app/router.dart
git commit -m "feat(design): debug component gallery + /gallery route"
```

---

### Task 24: Reskin Settings

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Test: `test/features/settings/settings_screen_test.dart` (create)

**Interfaces:**
- Consumes: `AppCard`, `AppSwitch`, `AppIcons`, tokens; `Routes.gallery`, `kDebugMode`; existing `appStringsProvider`, `settingsControllerProvider`.

*Behaviour unchanged: the toggle still drives `settingsControllerProvider.setProfanityEnabled`. In debug builds, add a row that navigates to `/gallery`.*

- [ ] **Step 1: Write the failing test**

```dart
// test/features/settings/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/widgets/app_switch.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('toggling the AppSwitch flips profanity mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    expect(find.byType(AppSwitch), findsOneWidget);
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(prefs.getBool('profanity_enabled'), isTrue);
  });
}
```

> If `settings_repository.dart` uses a different preferences key than `profanity_enabled`, read that file and use its actual key in the assertion.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/settings_screen_test.dart`
Expected: FAIL — `AppSwitch` not found in the (still `SwitchListTile`-based) screen.

- [ ] **Step 3: Rewrite the screen**

```dart
// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/design.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final profanityEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.profanityEnabled),
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          AppCard(
            child: Row(
              children: [
                Icon(AppIcons.mood, color: AppColors.brand),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.profanityTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(strings.profanitySubtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                AppSwitch(
                  value: profanityEnabled,
                  onChanged: (v) => ref
                      .read(settingsControllerProvider.notifier)
                      .setProfanityEnabled(v),
                ),
              ],
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.x4),
            AppCard(
              onTap: () => context.push(Routes.gallery),
              interactive: true,
              child: Row(
                children: [
                  Icon(AppIcons.checklist, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.x4),
                  const Expanded(child: Text('Design gallery (debug)')),
                  Icon(AppIcons.expandMore, color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify pass**

Run: `flutter test test/features/settings/settings_screen_test.dart && flutter analyze`
Expected: PASS; analyze clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart test/features/settings/settings_screen_test.dart
git commit -m "feat(settings): reskin with AppCard + AppSwitch + debug gallery link"
```

---

### Task 25: Reskin Today screen + empty state

**Files:**
- Modify: `lib/features/tasks/presentation/today_screen.dart`
- Test: `test/widget_test.dart` (verify existing assertions still hold)

**Interfaces:**
- Consumes: `design.dart`, `AppTaskItem`, `AppIcons`, tokens; existing `todayChecklistProvider`, `firebaseReadyProvider`, `appStringsProvider`, `starterSuggestionsByCategoryProvider`, `Routes.settings`.

*Behaviour unchanged: FAB and suggestion taps keep `_showComingSoon` with `strings.comingSoon`. Offline notice keeps `strings.firebaseNotConfigured` text (so `test/widget_test.dart` still passes). Empty title/body keep existing strings.*

- [ ] **Step 1: Confirm the existing widget test still expresses the contract**

`test/widget_test.dart` asserts `find.text('Today')`, `find.text('Nothing on your list today')`, and `find.textContaining('Firebase is not configured')`. Keep all three strings rendered after the reskin. No edit needed yet; this step is a read to lock the contract.

- [ ] **Step 2: Rewrite the screen**

```dart
// lib/features/tasks/presentation/today_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/design.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/tasks_providers.dart';
import '../domain/task_suggestion.dart';
import 'widgets/task_item.dart';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// The home screen: today's checklist. Behaviour is the P0 placeholder
/// (empty checklist + starter suggestions, "coming soon" on add); this slice
/// only restyles it with the design system.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklist = ref.watch(todayChecklistProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.todayTitle),
        actions: [
          AppIconButton(
            icon: AppIcons.settings,
            tooltip: strings.settingsTitle,
            onPressed: () => context.push(Routes.settings),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
      ),
      body: Column(
        children: [
          if (!firebaseReady)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppLayout.screenPad, 0, AppLayout.screenPad, AppSpacing.x2),
              child: AppBanner(
                message: strings.firebaseNotConfigured,
                tone: AppBannerTone.offline,
              ),
            ),
          Expanded(
            child: checklist.isEmpty
                ? const _EmptyStateWithSuggestions()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppLayout.screenPad,
                        AppSpacing.x2, AppLayout.screenPad, AppSpacing.x11),
                    itemCount: checklist.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x2),
                    itemBuilder: (context, index) =>
                        AppTaskItem(title: checklist[index].taskId),
                  ),
          ),
        ],
      ),
      floatingActionButton: AppButton(
        label: strings.addTask,
        icon: AppIcons.add,
        pill: true,
        onPressed: () => _showComingSoon(context, strings.comingSoon),
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _EmptyStateWithSuggestions extends ConsumerWidget {
  const _EmptyStateWithSuggestions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final grouped = ref.watch(starterSuggestionsByCategoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppLayout.screenPad, AppSpacing.x6,
          AppLayout.screenPad, AppSpacing.x11),
      children: [
        const Center(child: AppBrandMark(size: 72)),
        const SizedBox(height: AppSpacing.x4),
        Text(strings.emptyTitle,
            style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.x2),
        Text(strings.emptyBody,
            style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.x6),
        Text(strings.suggestionsHeader, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(strings.suggestionsSubtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.x4),
        for (final entry in grouped.entries) ...[
          _SuggestionGroup(category: entry.key, suggestions: entry.value),
          const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

class _SuggestionGroup extends ConsumerWidget {
  const _SuggestionGroup({required this.category, required this.suggestions});

  final String category;
  final List<TaskSuggestion> suggestions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weekday = _weekdayNames[suggestions.first.weekday - 1];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category, style: theme.textTheme.titleMedium),
              ),
              AppChip(label: weekday, tone: AppChipTone.today),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          for (final suggestion in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x2),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showComingSoon(
                    context, ref.read(appStringsProvider).comingSoon),
                child: Row(
                  children: [
                    Icon(AppIcons.addCircle,
                        size: 20, color: AppColors.brand),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Text(suggestion.title,
                          style: theme.textTheme.bodyLarge),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    AppBadge(label: '~${suggestion.estimatedEffortMinutes}m'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run the existing widget test + analyze**

Run: `flutter test test/widget_test.dart && flutter analyze`
Expected: PASS (Today / empty-title / Firebase-notice strings still render); analyze clean.

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/presentation/today_screen.dart
git commit -m "feat(tasks): reskin Today + empty state with the design system"
```

---

### Task 26: Final verification & cleanup

**Files:**
- Modify: any files flagged by `dart format` / `flutter analyze`.

- [ ] **Step 1: Format the whole project**

Run: `dart format .`
Expected: files formatted; re-run shows "0 changed".

- [ ] **Step 2: Analyze**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: all tests pass (design token/widget tests, task item, settings, existing `scheduling_test`, `settings_test`, `starter_tasks_test`, `widget_test`).

- [ ] **Step 4: Build the priority target**

Run: `flutter build apk --debug`
Expected: build succeeds (fonts bundled, icons tree-shaken, no asset errors).

- [ ] **Step 5: Commit any formatting/cleanup**

```bash
git add -A
git commit -m "chore: format + final foundation verification"
```

---

## Self-review

**Spec coverage** (spec → task):
- Token layer (colour/type/spacing/shadow/motion/icons) → Tasks 2–7. ✓
- Themed `MaterialApp` light + dark → Task 8. ✓
- Bundled fonts + Material Symbols → Task 1. ✓
- 12-widget library → Tasks 9–20 (Badge, Checkbox, Card, Chip, Button, IconButton, Switch, SegmentedControl, ProgressMeter, Avatar, Banner) + BrandMark (Task 20). ✓
- `AppTaskItem` (feature-local) → Task 22. ✓
- Barrels → Task 21. ✓
- Reskin Today/empty/Settings → Tasks 24–25. ✓
- Debug gallery + route → Task 23. ✓
- Behavioural tests + clean analyze/format + green tests + apk build → per-task tests + Task 26. ✓
- Out-of-scope honoured: no scheduler/persistence/CRUD; "Add task" stays "coming soon" → Task 25 keeps `_showComingSoon`. ✓

**Placeholder scan:** No TBD/TODO; every code step shows full code; commands have expected output. Two version-sensitive notes are explicit (Symbols.* constant names in Task 7; the prefs key in Task 24) with a concrete fallback action. ✓

**Type consistency:** `AppCheckbox(value/onChanged)`, `AppBadge(label/tone/soft)`, `AppButtonVariant`/`AppButtonSize`, `AppChipTone`, `AppBannerTone`, `AppIconButtonTone`, `AppSegment`/`AppSegmentedControl`, `AppProgressMeter(value/max)` key `appProgressMeterFill`, `AppTaskItem(title/minutes/category/done/movedFrom/onToggle)` — names used in tests and the gallery match their definitions. `AppMotion.of`, `AppTypography.mono`, `AppColors.*`, `AppRadii.*`, `AppShadows.*` consistent throughout. ✓

## Notes for the implementer

- Widgets import tokens via `../tokens/tokens.dart`; screens import the top-level `../core/design/design.dart` barrel.
- `withValues(alpha:)` is the current (non-deprecated) Flutter API for opacity on `Color`; if the pinned SDK predates it, substitute `withOpacity(...)`.
- If `flutter analyze` flags the documentation-only `_base`/`_ink` field in `app_shadows.dart`, delete it — it exists only to record provenance.
- Variable fonts cover all weights via the `wght` axis; no per-weight asset entries are needed.
