import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/strings/app_strings.dart';
import '../../settings/application/settings_providers.dart';
import '../application/tasks_providers.dart';
import '../domain/effort_learning.dart';
import '../domain/scheduling/recurrence_description.dart';
import '../domain/scheduling/task_occurrence.dart';
import 'task_composer_sheet.dart';

const _wkdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime d) {
  final wd = _wkdayShort[d.weekday - 1];
  final mon = _monthShort[d.month - 1];
  return '$wd ${d.day} $mon';
}

/// Task detail / history screen.
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskByIdProvider(taskId));
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This task is no longer here.')),
      );
    }

    final history = ref.watch(occurrencesForTaskProvider(taskId));
    final actuals = recentActualMinutes(history);
    final estimate = task.estimatedEffortMinutes;
    final learned = learnedEstimateMinutes(actuals, fallback: estimate);

    // Done occurrences with a recorded duration, sorted ascending by completedAt.
    final effortOccs =
        history
            .where(
              (o) =>
                  o.status == OccurrenceStatus.done &&
                  o.actualDurationMinutes != null,
            )
            .toList()
          ..sort((a, b) {
            final at = a.completedAt ?? a.scheduledDate;
            final bt = b.completedAt ?? b.scheduledDate;
            return at.compareTo(bt);
          });
    final recentEffort = effortOccs.length > 10
        ? effortOccs.sublist(effortOccs.length - 10)
        : effortOccs;

    // History: done/skipped/rescheduled, newest first.
    final historyOccs =
        history
            .where(
              (o) =>
                  o.status == OccurrenceStatus.done ||
                  o.status == OccurrenceStatus.skipped ||
                  o.status == OccurrenceStatus.rescheduled,
            )
            .toList()
          ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        actions: [
          AppIconButton(
            icon: AppIcons.edit,
            tooltip: 'Edit',
            onPressed: () => showTaskComposer(context, existing: task),
          ),
          AppIconButton(
            icon: AppIcons.delete,
            tooltip: strings.deleteConfirm,
            onPressed: () => _confirmDelete(context, ref, strings),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          // ── Header card ────────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.category != null) ...[
                  AppChip(label: task.category!, tone: AppChipTone.brand),
                  const SizedBox(height: AppSpacing.x3),
                ],
                Text(
                  describeRecurrence(task.recurrence),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.x3),
                Row(
                  children: [
                    Text(
                      strings.estimateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    AppBadge(label: '~${estimate}m', tone: AppBadgeTone.brand),
                  ],
                ),
              ],
            ),
          ),

          // ── Learned insight banner ──────────────────────────────────────
          if (actuals.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x3),
            AppBanner(
              tone: AppBannerTone.gentle,
              message:
                  '${strings.learnedPrefix} ~${learned}m — '
                  '${isQuickerThanExpected(learned, estimate) ? strings.learnedQuicker : strings.learnedSettled}',
            ),
          ],

          const SizedBox(height: AppSpacing.x4),

          // ── Effort card ─────────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.effortHeading, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.x3),
                if (recentEffort.isEmpty)
                  Text(strings.noEffortYet, style: theme.textTheme.bodyMedium)
                else
                  _EffortChart(
                    occurrences: recentEffort,
                    estimate: estimate,
                    estimateLabel: strings.estimateLabel,
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.x4),

          // ── History card ────────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.historyHeading,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.x3),
                if (historyOccs.isEmpty)
                  Text(strings.noHistoryYet, style: theme.textTheme.bodyMedium)
                else
                  Column(
                    children: [
                      for (final occ in historyOccs) ...[
                        _HistoryRow(
                          occ: occ,
                          estimate: estimate,
                          strings: strings,
                        ),
                        if (occ != historyOccs.last)
                          const SizedBox(height: AppSpacing.x3),
                      ],
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.x11),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.deleteTaskTitle),
        content: Text(strings.deleteTaskBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.deleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(taskServiceProvider)?.deleteTask(taskId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.taskDeleted)));
  }
}

// ── Effort bar chart ──────────────────────────────────────────────────────────

class _EffortChart extends StatelessWidget {
  const _EffortChart({
    required this.occurrences,
    required this.estimate,
    required this.estimateLabel,
  });

  final List<TaskOccurrence> occurrences;
  final int estimate;
  final String estimateLabel;

  @override
  Widget build(BuildContext context) {
    final actuals = occurrences.map((o) => o.actualDurationMinutes!).toList();
    final maxActual = actuals.reduce(max);
    final maxVal = max(maxActual, estimate).toDouble();
    const barHeight = 110.0;
    const baselineOffset = 16.0; // room for the labels below bars

    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          // Estimate reference line.
          Positioned(
            bottom: (estimate / maxVal) * barHeight + baselineOffset,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 1.5, color: AppColors.ink300),
                ),
                const SizedBox(width: 4),
                Text(estimateLabel, style: AppTypography.mono(size: 10)),
              ],
            ),
          ),
          // Bars row.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final actual in actuals)
                  _Bar(
                    actual: actual,
                    estimate: estimate,
                    maxVal: maxVal,
                    maxBarHeight: barHeight,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.actual,
    required this.estimate,
    required this.maxVal,
    required this.maxBarHeight,
  });

  final int actual;
  final int estimate;
  final double maxVal;
  final double maxBarHeight;

  @override
  Widget build(BuildContext context) {
    final h = (actual / maxVal) * maxBarHeight;
    final color = actual > estimate ? AppColors.coral400 : AppColors.brand;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${actual}m', style: AppTypography.mono(size: 11)),
        const SizedBox(height: 2),
        Container(
          width: 18,
          height: h.clamp(2.0, maxBarHeight),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xs),
            ),
          ),
        ),
      ],
    );
  }
}

// ── History row ───────────────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.occ,
    required this.estimate,
    required this.strings,
  });

  final TaskOccurrence occ;
  final int estimate;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget pill;
    switch (occ.status) {
      case OccurrenceStatus.done:
        final mins = occ.actualDurationMinutes ?? estimate;
        pill = AppBadge(label: '~${mins}m', tone: AppBadgeTone.done);
      case OccurrenceStatus.skipped:
        pill = AppChip(
          label: strings.skippedLabel,
          tone: AppChipTone.reschedule,
        );
      case OccurrenceStatus.rescheduled:
        pill = AppChip(label: strings.movedLabel, tone: AppChipTone.reschedule);
      case OccurrenceStatus.pending:
        pill = const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            _formatDate(occ.scheduledDate),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        pill,
      ],
    );
  }
}
