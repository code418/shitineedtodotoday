# Foundation — SINTDT Design System in Flutter (Sub-project 0)

**Date:** 2026-06-27
**Status:** Approved (design); pending implementation plan
**Source design system:** `SINTDT Design System` (claude.ai/design project
`491593d7-a7a7-49bd-a6b2-f4a640050878`)

## Context

The app is at the **P0 scaffold**: a bare `ColorScheme.fromSeed(#4C6FFF)` theme
with no custom fonts or tokens, a placeholder `TodayScreen`
(`CheckboxListTile` + "coming soon" FAB), a Settings screen with the profanity
toggle, and stubbed domain logic (`PlaceholderScheduler`, empty
`todayChecklistProvider`).

A complete brand + product design system now exists, covering the whole roadmap
(P1–P5). Implementing all of it is a sequence of sub-projects:

0. **Foundation** *(this spec)* — tokens, theme, widget library, reskin.
1. P1 · MVP — task CRUD, real scheduler, checklist, persistence.
2. P2 · Forgiving scheduler — onboarding, load balancing, effort learning.
3. P3 · Reminders — FCM settings + dispatch.
4. P4 · Accounts & sharing.
5. P5 · Insight — trends, agenda, full bottom-nav shell.

This spec is **Sub-project 0** only. Each later phase gets its own
spec → plan → implement → review cycle.

## Goal & boundary

Turn the design system into a reusable Flutter foundation and re-skin the three
screens that exist today.

**In scope**
- Design **token layer** (colour, type, spacing, radii, shadows, motion, icons).
- A themed `MaterialApp` (light + a derived dark theme).
- Bundled brand fonts (Nunito, JetBrains Mono) + Material Symbols Rounded icons.
- A **12-widget reusable library** + the signature `AppTaskItem`.
- The `AppBrandMark` (in-app logo).
- **Reskin** of Today, the empty state, and Settings — behaviour unchanged.
- A debug-only **component gallery** screen.
- Behavioural widget tests; clean `flutter analyze`; `dart format`.

**Explicitly out of scope** (later slices): real task CRUD, the scheduling
engine, Firestore persistence, the bottom-nav app shell, and all P1–P5 product
screens. "Add task" continues to show the existing "coming soon" message.

## Decisions (confirmed)

| Decision | Choice |
|---|---|
| First slice | Foundation (tokens + library + reskin) |
| Font delivery | **Bundle as assets** (Nunito, JetBrains Mono .ttf in repo) |
| Icon delivery | **`material_symbols_icons` package** (bundled offline, const `Symbols.*`, tree-shakeable) |
| Dark mode | **Adapt a dark theme now** (best-effort from palette; not design-authoritative) |
| Dev gallery | **Include** a debug-only `/gallery` route |
| Widget naming | `App*` prefix (consistent with `AppTheme`/`AppStrings`; avoids Material name clashes) |
| Token API | Plain `static const` holders, not a `ThemeExtension` |
| Brand mark | Dependency-free `CustomPainter` (no `flutter_svg`) |

## File layout

```
lib/core/design/
  tokens/
    app_colors.dart      # raw ramps + semantic aliases
    app_typography.dart  # families, weights, scale, TextTheme builder
    app_spacing.dart     # 4px scale, radii, layout consts
    app_shadows.dart     # shadow-card / raised / pop / brand
    app_motion.dart      # durations + curves
    app_icons.dart       # curated Material Symbols glyph set (re-exports Symbols.*)
  widgets/
    app_button.dart
    app_icon_button.dart
    app_segmented_control.dart
    app_card.dart
    app_chip.dart
    app_badge.dart
    app_progress_meter.dart
    app_avatar.dart
    app_banner.dart
    app_checkbox.dart
    app_switch.dart
    app_brand_mark.dart
    widgets.dart         # barrel for widgets
  design.dart            # top-level barrel (tokens + widgets)
lib/app/theme.dart       # AppTheme — rebuilt to consume tokens (stays here)
lib/features/tasks/presentation/widgets/task_item.dart   # AppTaskItem (feature-local)
lib/core/design/gallery/gallery_screen.dart              # debug-only component gallery
assets/fonts/            # Nunito + JetBrains Mono .ttf
```

Generic primitives live in `core/design` so future surfaces (Android widgets,
WearOS — see CLAUDE.md) can reuse them. `AppTaskItem` is task-domain
presentation, so it lives under `features/tasks/`, honouring the layering rule
over the design tool's grouping.

## Token layer

Direct port of the design system's CSS custom properties into Dart. Plain
`abstract final class` holders with `static const` members.

### Colours (`app_colors.dart`)
Raw ramps verbatim from `tokens/colors.css`:
- `blue` 50–900 (brand/seed `blue500 #4C6FFF`)
- `sun` 200–600 (`sun500 #FFB23E`)
- `coral` 200–600 (`coral500 #FF8A5B`)
- `green` 200–600 (`green500 #2FBF71`)
- `red` 300–600 (`red500 #E5484D`)
- `ink` 50–900 (`ink900 #1B1D29`), `white`

Semantic aliases (what app code uses): `surfacePage` (ink50), `surfaceCard`
(white), `surfaceSunken` (ink100), `surfaceBrand` (blue500); `textPrimary`
(ink900), `textSecondary` (ink600), `textMuted` (ink500), `textOnBrand`,
`textBrand` (blue600); `brand`/`brandHover`/`brandPress`/`brandSoft`; status
`done` (green500), `reschedule` (coral500), `today` (sun500), `error` (red500)
plus their `*Soft` tints; borders `subtle`/`default`/`strong`; `focusRing`.

### Typography (`app_typography.dart`)
- Families: `Nunito` (sans), `JetBrains Mono` (mono).
- Weights: regular 400, medium 600, semibold 700, bold 800, black 900.
- Scale (px): display 40, h1 30, h2 24, h3 20, title 17, body 16, sm 14,
  xs 13, 2xs 11.
- Line heights: tight 1.15, snug 1.3, normal 1.5, relaxed 1.6.
- Tracking: tight −0.02em on large display sizes; caps 0.08em on overlines.
- Exposes a `buildTextTheme(Brightness)` mapping the scale onto Material's
  `TextTheme` slots, plus named mono styles for durations/counts.

### Spacing / radii / layout (`app_spacing.dart`)
- Space: 0,4,8,12,16,20,24,32,40,48,64,80 (`x0`…`x11`).
- Radii: xs 6, sm 10, md 14, lg 18, xl 24, xxl 32, pill 999.
- Layout: `tapMin` 48, `screenPad` 16, `contentMax` 480.

### Shadows (`app_shadows.dart`)
`List<BoxShadow>` for: `xs`, `sm`, `card`, `raised`, `pop`, `brand` (blue-tinted),
matching the rgba values in `tokens/spacing.css`.

### Motion (`app_motion.dart`)
- Durations: fast 120ms, normal 200ms, slow 320ms.
- Curves: `easeOut` (0.22,1,0.36,1), `soft` (0.4,0,0.2,1),
  `spring` (0.34,1.56,0.64,1).
- All motion respects reduced-motion (`MediaQuery.disableAnimations`).

### Icons (`app_icons.dart`)
Re-export the curated set of Material Symbols Rounded used in product from the
`material_symbols_icons` package: `checklist`, `add`, `add_circle`, `check`,
`wb_sunny`, `event_repeat`, `cloud_off`, `settings`,
`sentiment_very_satisfied`, `expand_more`, `close`, plus category/day glyphs
(`countertops`, `local_laundry_service`, `skillet`, `bathtub`, `weekend`,
`shopping_cart`, `delete`). Rounded style; `fill` used for emphasis (e.g. sun).

## Theme integration (`lib/app/theme.dart`)

Rebuild `AppTheme` to consume tokens instead of `fromSeed`:
- **Light** (authoritative): hand-built `ColorScheme.light` from the palette;
  `scaffoldBackgroundColor: AppColors.surfacePage` (ink50); white `CardThemeData`
  at `radius-xl` + `shadow-card`; `Nunito` `TextTheme` via `buildTextTheme`;
  brand-tinted `AppBarTheme` (flat, no centre title), `SnackBarTheme`,
  `BottomSheetTheme` (radius-2xl), input/focus styles using `focusRing`.
- **Dark** (derived, best-effort): deep ink surfaces (`ink900`/`ink800`),
  adjusted on-colours for contrast; same type scale, radii, motion. Marked in
  code as non-authoritative pending dark tokens in the design system.
- `app.dart` keeps `theme:`/`darkTheme:` and `themeMode: ThemeMode.system`.

## Widget library

All take their visual values from tokens. Each gets a behavioural widget test
and a gallery entry. Exact paddings/sizes per variant are taken from the design
system's `.jsx` sources during implementation.

| Widget | Spec |
|---|---|
| `AppButton` | `variant`: primary (brand fill + `shadow-brand`) / tonal (blue50 fill, blue text) / ghost (outline, border-default) / danger (red). `size`: sm/md/lg. `pill`, `block`, leading `icon` / trailing `iconRight`, `onPressed` (null = disabled). Press scales to 0.96 with `spring`. |
| `AppIconButton` | Round; `tone`: default / brand / onBrand. `size` (default 44 ≥ tapMin). `icon`, `onPressed`, `tooltip`. |
| `AppSegmentedControl<T>` | Pill-tracked tabs; `options` (label+value), `value`, `onChanged`, `size` sm/md. Animated thumb. |
| `AppCheckbox` | Round tick-box; `value`, `onChanged`, `size` (default 26), `color` (default `done` green). Springy tick on check. |
| `AppSwitch` | Pill toggle; `value`, `onChanged`. Brand when on. |
| `AppCard` | White, radius-xl, `shadow-card`, default padding `space-5`. `interactive` lifts to `shadow-raised` + 2px translate on hover/press. `onTap` optional. |
| `AppChip` | `tone`: neutral/brand/today/done/reschedule. `selectable` → outlined when unselected, filled when `selected`. Optional leading `icon`, `onTap`. |
| `AppBadge` | Mono pill (JetBrains Mono); `tone`: done/today/reschedule/brand or neutral; `soft` (default) vs solid. For durations/counts ("~15m"). |
| `AppProgressMeter` | `value`/`max` (minutes vs budget), `label`, `showValue`, `unit` ("m"), `height`. Fills brand; **tips to coral when value > max** (no shake/flash). Animated width. |
| `AppAvatar` | Initials from `name` (name-seeded tint) or `src` image; `size` (default 40); `color` forces solid bg + white text. |
| `AppBanner` | `tone`: info/offline/gentle/error (picks default icon + soft tint); `icon` override; optional trailing `action`. Soft inline strip; error is the only red, never used to scold. |
| `AppTaskItem` | **Signature row.** `title`, `minutes` (→ mono `~Nm` badge), `category`, `done`, `movedFrom` (gentle coral "moved from <day>" note via `event_repeat`), `onToggle`. Completed rows soften + strike through — never red. Round `AppCheckbox` tick. |

`AppBrandMark`: `CustomPainter` drawing the rounded gradient tile (blue400→blue600),
the amber sun (solid + 28%-opacity halo) and the white tick, from
`assets/sintdt-mark.svg`. Sizeable; used on the empty state.

## Fonts & icons delivery

- **Fonts**: download Nunito (400, 600, 700, 800, 900 + italic 400, 600) and
  JetBrains Mono (400, 500, 600) `.ttf` (OFL) into `assets/fonts/`; declare in
  `pubspec.yaml` `fonts:`.
- **Icons**: add `material_symbols_icons` to `pubspec.yaml`; use `Symbols.*`
  (Rounded) via `app_icons.dart`. Bundled offline; const IconData keeps icon
  tree-shaking working.

## Reskin (behaviour unchanged)

- **Today** (`today_screen.dart`): branded `AppBar`; FAB → `AppButton` primary
  pill ("Add task", still "coming soon"); checklist rows → `AppTaskItem`;
  offline notice → `AppBanner` (offline tone).
- **Empty state**: `AppBrandMark` + warm copy (existing `AppStrings`) + starter
  suggestions rebuilt with `AppCard` / `AppChip` (category/day) / `AppBadge`
  (`~Nm`). Tapping a suggestion keeps the current "coming soon".
- **Settings** (`settings_screen.dart`): profanity toggle → `AppSwitch`; rows in
  `AppCard`.
- `AppStrings` may gain a few keys if the reskin needs copy not present today;
  both registers stay in sync. Task content stays data (not routed through
  `AppStrings`).

## Dev gallery

A debug-only `/gallery` route (guarded by `kDebugMode`, linked from Settings in
debug builds) showing each token group and every widget in its variants. Serves
as living documentation and the visual-review surface for this slice.

## Testing

- Behavioural widget tests (not goldens, for CI stability):
  - `AppTaskItem` toggles and renders `movedFrom` / `done` states.
  - `AppProgressMeter` fills brand under budget, tips coral when over.
  - `AppButton` renders each variant and respects disabled.
  - `AppSwitch` drives the profanity provider on Settings.
  - Empty-state suggestions render with badges.
- Existing `test/` suite keeps passing (`widget_test.dart` updated for the new
  tree if needed).
- `flutter analyze` clean; `dart format .`; generated files unaffected.

## Acceptance criteria

1. App builds and runs (Android + web) with the new theme; no `fromSeed`.
2. Nunito + JetBrains Mono render from bundled assets; Material Symbols Rounded
   render via the package.
3. All 12 widgets + `AppTaskItem` + `AppBrandMark` exist, themed from tokens,
   each with a gallery entry and a widget test.
4. Today / empty state / Settings are reskinned; behaviour identical to today
   (no new product logic; "Add task" still "coming soon").
5. Light + dark themes both render coherently.
6. `flutter analyze` clean, `flutter test` green, `dart format` applied.

## Risks / notes

- Bundled font weights add ~1–2 MB to the app; acceptable for Android-first.
- Dark theme is derived, not design-authoritative — revisit when the design
  system defines dark tokens.
- `material_symbols_icons` is an extra dependency; pinned and offline.
- Exact per-variant pixel values come from the design system `.jsx` sources at
  implementation time; tokens above are the source of truth for colour/space.
