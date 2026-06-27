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
                AppLayout.screenPad,
                0,
                AppLayout.screenPad,
                AppSpacing.x2,
              ),
              child: AppBanner(
                message: strings.firebaseNotConfigured,
                tone: AppBannerTone.offline,
              ),
            ),
          Expanded(
            child: checklist.isEmpty
                ? const _EmptyStateWithSuggestions()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.screenPad,
                      AppSpacing.x2,
                      AppLayout.screenPad,
                      AppSpacing.x11,
                    ),
                    itemCount: checklist.length,
                    separatorBuilder: (_, _) =>
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
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPad,
        AppSpacing.x6,
        AppLayout.screenPad,
        AppSpacing.x11,
      ),
      children: [
        const Center(child: AppBrandMark(size: 72)),
        const SizedBox(height: AppSpacing.x4),
        Text(
          strings.emptyTitle,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          strings.emptyBody,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
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
                  context,
                  ref.read(appStringsProvider).comingSoon,
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.addCircle, size: 20, color: AppColors.brand),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Text(
                        suggestion.title,
                        style: theme.textTheme.bodyLarge,
                      ),
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
