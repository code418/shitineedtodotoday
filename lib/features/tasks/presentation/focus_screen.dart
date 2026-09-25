import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../settings/application/settings_providers.dart';
import '../application/tasks_providers.dart';
import '../domain/scheduling/task_occurrence.dart';
import 'log_duration_sheet.dart';

/// Focus mode: today's open chores one at a time, so a long list never has
/// to be faced all at once (P6 accessibility).
///
/// Works off the same checklist Today shows. "Done" is the usual
/// complete-with-duration sheet and "Not today" the usual skip, so nothing
/// here can disagree with Today; "Later" only reorders this session's queue.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  /// Occurrences sent to the back with "Later", in the order they were.
  final _later = <String>[];
  bool _busy = false;

  /// Today's open chores in checklist order, with "Later" ones moved last.
  List<TaskOccurrence> _queue(List<TaskOccurrence> open) {
    final later = _later.toSet();
    final byId = {for (final o in open) o.id: o};
    return [
      for (final o in open)
        if (!later.contains(o.id)) o,
      for (final id in _later)
        if (byId[id] != null) byId[id]!,
    ];
  }

  void _sendToBack(TaskOccurrence occurrence) => setState(() {
    _later
      ..remove(occurrence.id)
      ..add(occurrence.id);
  });

  Future<void> _skip(TaskOccurrence occurrence) async {
    final svc = ref.read(occurrenceServiceProvider);
    if (_busy || svc == null) return;
    final strings = ref.read(appStringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await svc.skip(occurrence);
      messenger.showSnackBar(SnackBar(content: Text(strings.taskSkipped)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.actionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final checklist = ref.watch(todayChecklistProvider);
    final queue = _queue([
      for (final o in checklist)
        if (o.isOpen) o,
    ]);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: AppIconButton(
          icon: AppIcons.close,
          tooltip: strings.close,
          onPressed: () => context.pop(),
        ),
        actions: [
          if (queue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppLayout.screenPad),
              child: Center(
                child: Text(
                  strings.focusProgressText(
                    left: queue.length,
                    total: checklist.length,
                  ),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.screenPad),
          child: queue.isEmpty
              ? _AllDone(onBack: () => context.pop())
              : _FocusCard(
                  occurrence: queue.first,
                  busy: _busy,
                  onSkip: _skip,
                  onLater: queue.length > 1 ? _sendToBack : null,
                ),
        ),
      ),
    );
  }
}

class _FocusCard extends ConsumerWidget {
  const _FocusCard({
    required this.occurrence,
    required this.busy,
    required this.onSkip,
    required this.onLater,
  });

  final TaskOccurrence occurrence;
  final bool busy;
  final ValueChanged<TaskOccurrence> onSkip;

  /// Null when this is the only chore left (nothing to put it behind).
  final ValueChanged<TaskOccurrence>? onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final task = ref.watch(taskByIdProvider(occurrence.taskId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // A live region, so a screen reader announces each new chore
                  // as the previous one is done, skipped or put off.
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      task?.title ?? occurrence.taskId,
                      key: const Key('focus-title'),
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (task != null) ...[
                    const SizedBox(height: AppSpacing.x4),
                    AppBadge(label: '~${task.estimatedEffortMinutes}m'),
                  ],
                  if (task?.category != null) ...[
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      task!.category!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.palette.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        AppButton(
          label: strings.focusDone,
          icon: AppIcons.check,
          block: true,
          pill: true,
          // The same complete-with-duration sheet as ticking it on Today.
          onPressed: busy || task == null
              ? null
              : () => showLogDurationSheet(
                  context,
                  occurrence: occurrence,
                  task: task,
                ),
        ),
        const SizedBox(height: AppSpacing.x3),
        AppButton(
          label: strings.notToday,
          variant: AppButtonVariant.tonal,
          block: true,
          pill: true,
          onPressed: busy ? null : () => onSkip(occurrence),
        ),
        const SizedBox(height: AppSpacing.x2),
        Center(
          child: TextButton(
            onPressed: busy || onLater == null
                ? null
                : () => onLater!(occurrence),
            child: Text(strings.focusLater),
          ),
        ),
      ],
    );
  }
}

class _AllDone extends ConsumerWidget {
  const _AllDone({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.check, size: 56, color: context.palette.done),
          const SizedBox(height: AppSpacing.x4),
          Semantics(
            liveRegion: true,
            child: Text(
              strings.focusAllDoneTitle,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            strings.focusAllDoneBody,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.x6),
          AppButton(
            label: strings.focusBackToToday,
            variant: AppButtonVariant.tonal,
            pill: true,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}
