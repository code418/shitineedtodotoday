import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../settings/application/settings_providers.dart';
import '../application/occurrence_service.dart';
import '../application/tasks_providers.dart';
import '../domain/effort_learning.dart';
import '../domain/scheduling/task_occurrence.dart';
import '../domain/task.dart';

const _quickPickMinutes = [5, 10, 15, 30, 45, 60];

/// Shows the "how long did it take?" sheet for a completed occurrence.
///
/// Awaiting the returned future resolves once the sheet is dismissed.
Future<void> showLogDurationSheet(
  BuildContext context, {
  required TaskOccurrence occurrence,
  required Task task,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LogDurationSheet(occurrence: occurrence, task: task),
  );
}

class _LogDurationSheet extends ConsumerStatefulWidget {
  const _LogDurationSheet({required this.occurrence, required this.task});

  final TaskOccurrence occurrence;
  final Task task;

  @override
  ConsumerState<_LogDurationSheet> createState() => _LogDurationSheetState();
}

class _LogDurationSheetState extends ConsumerState<_LogDurationSheet> {
  late int _minutes;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _minutes = widget.task.estimatedEffortMinutes.clamp(5, 120);
  }

  Future<void> _onLog() async {
    // Guard against a rapid double-tap completing (and writing) twice.
    if (_submitting) return;
    final strings = ref.read(appStringsProvider);
    final svc = ref.read(occurrenceServiceProvider);
    if (svc == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.firebaseNotConfigured)));
      return;
    }

    final history = ref.read(occurrencesForTaskProvider(widget.task.id));
    setState(() => _submitting = true);
    final CompletionResult result;
    try {
      result = await svc.complete(
        occurrence: widget.occurrence,
        task: widget.task,
        actualMinutes: _minutes,
        history: history,
      );
    } catch (_) {
      // Keep the sheet open so the user can retry logging the duration.
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.actionFailed)));
      return;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    if (result.updatedTask != null) {
      final learned = result.updatedTask!.estimatedEffortMinutes;
      final isQuicker = isQuickerThanExpected(
        learned,
        widget.task.estimatedEffortMinutes,
      );
      final feedback = isQuicker
          ? strings.learnedQuicker
          : strings.learnedSettled;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${strings.learnedPrefix} ~${learned}m — $feedback'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final keyboardPad = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPad),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.durationPrompt, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.x1),
            Text(
              strings.durationSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.x4),

            // Quick-pick chips
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                for (final m in _quickPickMinutes)
                  AppChip(
                    label: '${m}m',
                    selectable: true,
                    selected: _minutes == m,
                    onTap: () => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),

            // Slider with current value badge
            Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 5,
                    max: 120,
                    divisions: 23,
                    value: _minutes.toDouble(),
                    onChanged: (v) => setState(() => _minutes = v.round()),
                  ),
                ),
                AppBadge(label: '~${_minutes}m', tone: AppBadgeTone.brand),
              ],
            ),

            const SizedBox(height: AppSpacing.x5),
            AppButton(
              label: strings.durationSave,
              block: true,
              pill: true,
              onPressed: _submitting ? null : _onLog,
            ),
            const SizedBox(height: AppSpacing.x2),
          ],
        ),
      ),
    );
  }
}
