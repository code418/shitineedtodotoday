import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
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
        onPressed: () => _showComingSoon(context),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Adding tasks arrives in the next milestone.'),
    ),
  );
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
          'Nothing on your list today',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Pick a few ready-made tasks to get started — or add your own. '
          "We'll build a manageable daily checklist from them.",
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text('Suggested starters', style: theme.textTheme.titleMedium),
        Text(
          'A gentle weekly cleaning routine, split into themed days.',
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

class _SuggestionGroup extends StatelessWidget {
  const _SuggestionGroup({required this.category, required this.suggestions});

  final String category;
  final List<TaskSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
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
              onTap: () => _showComingSoon(context),
            ),
        ],
      ),
    );
  }
}

class _FirebaseNotConfiguredBanner extends StatelessWidget {
  const _FirebaseNotConfiguredBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                'Firebase is not configured. Run `flutterfire configure` to '
                'enable sync and reminders.',
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
