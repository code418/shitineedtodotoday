import '../domain/task_suggestion.dart';

/// Ready-made starter tasks offered to new users.
///
/// Transcribed from the "Daily Cleaning Planner" — an ADHD-friendly weekly
/// routine that splits the house into themed days with a manageable daily time
/// budget. Each task keeps the planner's own average time estimate so the
/// scheduler can balance a realistic day from the very first use.
///
/// Themed days & rough daily budgets:
///   Mon Reset & Surfaces (~55m) · Tue Laundry & Bedrooms (~55m) ·
///   Wed Kitchen & Bedding (~55m) · Thu Bathrooms & Mail (~45m) ·
///   Fri Living Room & Car (~55m) · Sat Groceries & Meals (~95m) ·
///   Sun Trash & Prep (~40m)
const List<TaskSuggestion> kStarterCleaningPlan = [
  // ── Monday — Reset & Surfaces ─────────────────────────────────────────────
  TaskSuggestion(
    key: 'mon-kitchen-surfaces',
    title: 'Clear & wipe down kitchen surfaces',
    category: 'Reset & Surfaces',
    weekday: DateTime.monday,
    estimatedEffortMinutes: 15,
  ),
  TaskSuggestion(
    key: 'mon-bathroom-surfaces',
    title: 'Clean bathroom surfaces',
    category: 'Reset & Surfaces',
    weekday: DateTime.monday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'mon-tidy-living-room',
    title: 'Quick tidy of living room',
    category: 'Reset & Surfaces',
    weekday: DateTime.monday,
    estimatedEffortMinutes: 15,
  ),
  TaskSuggestion(
    key: 'mon-entryway-reset',
    title: 'Entryway reset',
    category: 'Reset & Surfaces',
    weekday: DateTime.monday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'mon-vacuum-walkways',
    title: 'Light vacuum of walkways',
    category: 'Reset & Surfaces',
    weekday: DateTime.monday,
    estimatedEffortMinutes: 15,
  ),

  // ── Tuesday — Laundry & Bedrooms ──────────────────────────────────────────
  TaskSuggestion(
    key: 'tue-collect-wash-clothes',
    title: 'Collect & wash clothes',
    category: 'Laundry & Bedrooms',
    weekday: DateTime.tuesday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'tue-dry-clothes',
    title: 'Dry clothes',
    category: 'Laundry & Bedrooms',
    weekday: DateTime.tuesday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'tue-fold-put-away-clothes',
    title: 'Fold & put away clothes',
    category: 'Laundry & Bedrooms',
    weekday: DateTime.tuesday,
    estimatedEffortMinutes: 15,
  ),
  TaskSuggestion(
    key: 'tue-reset-bedroom-surfaces',
    title: 'Reset bedroom surfaces',
    category: 'Laundry & Bedrooms',
    weekday: DateTime.tuesday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'tue-tidy-nightstands',
    title: 'Tidy nightstands',
    category: 'Laundry & Bedrooms',
    weekday: DateTime.tuesday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'tue-floor-sweep-vacuum',
    title: 'Quick floor sweep/vacuum',
    category: 'Laundry & Bedrooms',
    weekday: DateTime.tuesday,
    estimatedEffortMinutes: 15,
  ),

  // ── Wednesday — Kitchen & Bedding ─────────────────────────────────────────
  TaskSuggestion(
    key: 'wed-stovetop-microwave',
    title: 'Clean stovetop & microwave',
    category: 'Kitchen & Bedding',
    weekday: DateTime.wednesday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'wed-light-living-room',
    title: 'Light cleanup of living room',
    category: 'Kitchen & Bedding',
    weekday: DateTime.wednesday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'wed-wash-dishes',
    title: 'Wash/load dishes',
    category: 'Kitchen & Bedding',
    weekday: DateTime.wednesday,
    estimatedEffortMinutes: 20,
  ),
  TaskSuggestion(
    key: 'wed-organize-drawer',
    title: 'Organize small area/drawer',
    category: 'Kitchen & Bedding',
    weekday: DateTime.wednesday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'wed-wash-bedding',
    title: 'Wash bedding',
    category: 'Kitchen & Bedding',
    weekday: DateTime.wednesday,
    estimatedEffortMinutes: 10,
  ),

  // ── Thursday — Bathrooms & Mail ───────────────────────────────────────────
  TaskSuggestion(
    key: 'thu-clean-toilets',
    title: 'Clean toilets',
    category: 'Bathrooms & Mail',
    weekday: DateTime.thursday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'thu-sink-faucets',
    title: 'Clean sink + faucets',
    category: 'Bathrooms & Mail',
    weekday: DateTime.thursday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'thu-wipe-mirrors',
    title: 'Wipe mirrors',
    category: 'Bathrooms & Mail',
    weekday: DateTime.thursday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'thu-scrub-shower-tubs',
    title: 'Quick scrub shower/tubs',
    category: 'Bathrooms & Mail',
    weekday: DateTime.thursday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'thu-mop-bathroom-floor',
    title: 'Sweep/mop bathroom floor',
    category: 'Bathrooms & Mail',
    weekday: DateTime.thursday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'thu-sort-mail-bills',
    title: 'Sort mail/pay bills',
    category: 'Bathrooms & Mail',
    weekday: DateTime.thursday,
    estimatedEffortMinutes: 10,
  ),

  // ── Friday — Living Room & Car ────────────────────────────────────────────
  TaskSuggestion(
    key: 'fri-vacuum-rooms',
    title: 'Vacuum rooms/living area',
    category: 'Living Room & Car',
    weekday: DateTime.friday,
    estimatedEffortMinutes: 20,
  ),
  TaskSuggestion(
    key: 'fri-pick-up-toys',
    title: 'Pick up toys/items',
    category: 'Living Room & Car',
    weekday: DateTime.friday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'fri-clear-tables',
    title: 'Clear kitchen/dining table(s)',
    category: 'Living Room & Car',
    weekday: DateTime.friday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'fri-tidy-kids-spaces',
    title: "Quick tidy of kids' spaces",
    category: 'Living Room & Car',
    weekday: DateTime.friday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'fri-car-quick-clean',
    title: 'Car quick clean',
    category: 'Living Room & Car',
    weekday: DateTime.friday,
    estimatedEffortMinutes: 10,
  ),

  // ── Saturday — Groceries & Meals ──────────────────────────────────────────
  TaskSuggestion(
    key: 'sat-meal-plan',
    title: 'Meal plan (loose or detailed)',
    category: 'Groceries & Meals',
    weekday: DateTime.saturday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'sat-grocery-shop',
    title: 'Grocery shop or place order',
    category: 'Groceries & Meals',
    weekday: DateTime.saturday,
    estimatedEffortMinutes: 60,
  ),
  TaskSuggestion(
    key: 'sat-tidy-pantry',
    title: 'Tidy pantry/check staples',
    category: 'Groceries & Meals',
    weekday: DateTime.saturday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'sat-prep-snacks',
    title: 'Prep snacks/foods',
    category: 'Groceries & Meals',
    weekday: DateTime.saturday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'sat-put-away-groceries',
    title: 'Put away groceries',
    category: 'Groceries & Meals',
    weekday: DateTime.saturday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'sat-mop-kitchen-floor',
    title: 'Sweep/mop kitchen floor',
    category: 'Groceries & Meals',
    weekday: DateTime.saturday,
    estimatedEffortMinutes: 10,
  ),

  // ── Sunday — Trash & Prep ─────────────────────────────────────────────────
  TaskSuggestion(
    key: 'sun-clear-fridge',
    title: 'Clear out fridge',
    category: 'Trash & Prep',
    weekday: DateTime.sunday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'sun-refresh-living-room',
    title: 'Refresh living room',
    category: 'Trash & Prep',
    weekday: DateTime.sunday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'sun-prep-backpacks',
    title: 'Prep backpacks for Monday',
    category: 'Trash & Prep',
    weekday: DateTime.sunday,
    estimatedEffortMinutes: 5,
  ),
  TaskSuggestion(
    key: 'sun-quick-sweep',
    title: 'Quick sweep/vacuum',
    category: 'Trash & Prep',
    weekday: DateTime.sunday,
    estimatedEffortMinutes: 10,
  ),
  TaskSuggestion(
    key: 'sun-empty-trash',
    title: 'Empty trash/recycling',
    category: 'Trash & Prep',
    weekday: DateTime.sunday,
    estimatedEffortMinutes: 10,
  ),
];
