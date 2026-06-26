import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/tasks_providers.dart';
import '../domain/task_suggestion.dart';

/// The home screen: today's checklist.
///
/// This is a scaffold placeholder — it renders the (currently empty) checklist
/// from [todayChecklistProvider], and when there's nothing yet it offers the
/// ready-made starter plan from [starterSuggestionsByCategoryProvider].
/// Actually adding/persisting tasks arrives in P1 (see `docs/ROADMAP.md`).
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: strings.settingsTitle,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!firebaseReady) const _FirebaseNotConfiguredBanner(),
          Expanded(
            child: checklist.isEmpty
                ? const _EmptyStateWithSuggestions()
                : ListView.builder(
                    itemCount: checklist.length,
                    itemBuilder: (context, index) {
                      final occurrence = checklist[index];
                      return CheckboxListTile(
                        value: false,
                        onChanged: null,
                        title: Text(occurrence.taskId),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComingSoon(context, strings.comingSoon),
        icon: const Icon(Icons.add),
        label: Text(strings.addTask),
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class _EmptyStateWithSuggestions extends ConsumerWidget {
  const _EmptyStateWithSuggestions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final grouped = ref.watch(starterSuggestionsByCategoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
      children: [
        Icon(
          Icons.checklist_rounded,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          strings.emptyTitle,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          strings.emptyBody,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(strings.suggestionsHeader, style: theme.textTheme.titleMedium),
        Text(
          strings.suggestionsSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in grouped.entries)
          _SuggestionGroup(category: entry.key, suggestions: entry.value),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        title: Text(category, style: theme.textTheme.titleSmall),
        subtitle: Text('$weekday · ${suggestions.length} tasks'),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (final suggestion in suggestions)
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_circle_outline),
              title: Text(suggestion.title),
              trailing: Text(
                '~${suggestion.estimatedEffortMinutes}m',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => _showComingSoon(
                context,
                ref.read(appStringsProvider).comingSoon,
              ),
            ),
        ],
      ),
    );
  }
}

class _FirebaseNotConfiguredBanner extends ConsumerWidget {
  const _FirebaseNotConfiguredBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.firebaseNotConfigured,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
