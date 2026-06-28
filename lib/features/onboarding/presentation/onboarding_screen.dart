import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/design.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/util/date_labels.dart';
import '../../settings/application/settings_providers.dart';
import '../../tasks/application/tasks_providers.dart';
import '../../tasks/domain/task_suggestion.dart';

/// First-run onboarding wizard: Welcome → pace → pick starters → Today.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Set of category names whose starter tasks the user wants to add.
  late Set<String> _selectedCategories;
  bool _initialized = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initSelectedIfNeeded(Map<String, List<TaskSuggestion>> grouped) {
    if (!_initialized) {
      _selectedCategories = Set.of(grouped.keys);
      _initialized = true;
    }
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish({required bool addSelected}) async {
    final strings = ref.read(appStringsProvider);
    final svc = ref.read(taskServiceProvider);

    var seedFailed = false;
    if (addSelected && svc != null) {
      final grouped = ref.read(starterSuggestionsByCategoryProvider);
      try {
        for (final entry in grouped.entries) {
          if (_selectedCategories.contains(entry.key)) {
            for (final suggestion in entry.value) {
              await svc.addFromSuggestion(suggestion);
            }
          }
        }
      } catch (_) {
        // Seeding starter tasks failed (e.g. a write error). Don't trap the
        // user on onboarding — finish anyway; they can add tasks later.
        seedFailed = true;
      }
    }

    // Always mark onboarding complete so the user is never stuck on this screen
    // on every launch, even if seeding their starter tasks failed.
    await ref
        .read(settingsControllerProvider.notifier)
        .setOnboardingComplete(true);

    if (!mounted) return;
    context.go(Routes.today);
    if (seedFailed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.actionFailed)));
    } else if (addSelected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.onboardingAdded)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final budget = ref.watch(dailyEnergyBudgetProvider);
    final grouped = ref.watch(starterSuggestionsByCategoryProvider);
    _initSelectedIfNeeded(grouped);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button in the top-right.
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.screenPad,
                  AppSpacing.x3,
                  AppLayout.screenPad,
                  0,
                ),
                child: TextButton(
                  onPressed: () => _finish(addSelected: false),
                  child: Text(
                    strings.skipForNow,
                    style: TextStyle(
                      fontFamily: AppTypography.fontSans,
                      fontSize: AppTypography.sizeSm,
                      fontWeight: AppTypography.medium,
                      color: context.palette.textMuted,
                    ),
                  ),
                ),
              ),
            ),

            // Page content.
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(strings: strings),
                  _PacePage(
                    strings: strings,
                    budget: budget,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .setDailyEnergyBudget(v.round()),
                  ),
                  _PickPage(
                    strings: strings,
                    grouped: grouped,
                    selectedCategories: _selectedCategories,
                    onToggle: (category) {
                      setState(() {
                        if (_selectedCategories.contains(category)) {
                          _selectedCategories.remove(category);
                        } else {
                          _selectedCategories.add(category);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Page dots + bottom action buttons.
            _BottomBar(
              page: _page,
              totalPages: 3,
              strings: strings,
              onBack: _page > 0 ? () => _goToPage(_page - 1) : null,
              onNext: _page < 2
                  ? () => _goToPage(_page + 1)
                  : () => _finish(addSelected: true),
              nextLabel: _page < 2
                  ? strings.onboardingNext
                  : strings.getStarted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 0 — Welcome
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.screenPad * 2,
        vertical: AppSpacing.x6,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.x6),
          const AppBrandMark(size: 96),
          const SizedBox(height: AppSpacing.x6),
          Text(
            strings.welcomeTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            strings.welcomeBody,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.palette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — Daily pace
// ─────────────────────────────────────────────────────────────────────────────

class _PacePage extends StatelessWidget {
  const _PacePage({
    required this.strings,
    required this.budget,
    required this.onChanged,
  });

  final AppStrings strings;
  final int budget;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.screenPad,
        vertical: AppSpacing.x6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.x4),
          Text(strings.paceStepTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.x2),
          Text(
            strings.paceStepBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          Center(
            child: AppBadge(label: '${budget}m', tone: AppBadgeTone.brand),
          ),
          const SizedBox(height: AppSpacing.x4),
          Slider(
            value: budget.toDouble(),
            min: 15,
            max: 180,
            divisions: 33,
            onChanged: onChanged,
            activeColor: context.palette.brand,
            inactiveColor: context.palette.brandSoft,
          ),
          const SizedBox(height: AppSpacing.x2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '15m',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.textMuted,
                ),
              ),
              Text(
                '3h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — Pick starter routine
// ─────────────────────────────────────────────────────────────────────────────

class _PickPage extends StatelessWidget {
  const _PickPage({
    required this.strings,
    required this.grouped,
    required this.selectedCategories,
    required this.onToggle,
  });

  final AppStrings strings;
  final Map<String, List<TaskSuggestion>> grouped;
  final Set<String> selectedCategories;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPad,
        AppSpacing.x4,
        AppLayout.screenPad,
        AppSpacing.x4,
      ),
      children: [
        Text(strings.pickStepTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.x2),
        Text(
          strings.pickStepBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        for (final entry in grouped.entries) ...[
          _CategoryCard(
            category: entry.key,
            suggestions: entry.value,
            selected: selectedCategories.contains(entry.key),
            onToggle: () => onToggle(entry.key),
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.suggestions,
    required this.selected,
    required this.onToggle,
  });

  final String category;
  final List<TaskSuggestion> suggestions;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekday = kWeekdayNamesLong[suggestions.first.weekday - 1];

    return AppCard(
      onTap: onToggle,
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Row(
        children: [
          // Leading selection indicator.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: selected ? context.palette.brand : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? context.palette.brand
                    : context.palette.borderStrong,
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(AppIcons.check, size: 16, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.x3),

          // Category name + weekday chip.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  weekday,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x3),

          // Task count badge.
          AppBadge(label: '${suggestions.length} tasks'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar: dots + back/next buttons
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.page,
    required this.totalPages,
    required this.strings,
    required this.onNext,
    required this.nextLabel,
    this.onBack,
  });

  final int page;
  final int totalPages;
  final AppStrings strings;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPad,
        AppSpacing.x3,
        AppLayout.screenPad,
        AppSpacing.x6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page dots.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < totalPages; i++) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: i == page ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == page
                        ? context.palette.brand
                        : context.palette.borderDefault,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
                if (i < totalPages - 1) const SizedBox(width: AppSpacing.x2),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.x4),

          // Action buttons.
          Row(
            children: [
              if (onBack != null) ...[
                Expanded(
                  child: AppButton(
                    label: strings.onboardingBack,
                    variant: AppButtonVariant.ghost,
                    block: true,
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
              ],
              Expanded(
                child: AppButton(
                  label: nextLabel,
                  block: true,
                  onPressed: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
