import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../application/tasks_providers.dart';

/// The home screen: today's checklist.
///
/// This is a scaffold placeholder — it renders the (currently empty) checklist
/// from [todayChecklistProvider] and an empty state. Task creation, completion
/// and effort logging arrive in P1 (see `docs/ROADMAP.md`).
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
                ? const _EmptyState()
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
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task creation arrives in the next milestone.'),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing on your list today',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a task and choose how often it needs doing — '
              "we'll build a manageable daily checklist for you.",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
