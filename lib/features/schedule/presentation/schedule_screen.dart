import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/util/date_labels.dart';
import '../../settings/application/settings_providers.dart';
import '../../tasks/application/tasks_providers.dart';
import '../../tasks/domain/scheduling/forgiving_scheduler.dart' show dateOnly;
import '../../tasks/domain/scheduling/task_occurrence.dart';
import '../application/schedule_providers.dart';
import '../domain/agenda.dart';

/// The week-agenda screen: seven day columns the user can drag tasks between.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final week = ref.watch(weekAgendaProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: Text(strings.scheduleTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          // Drag hint.
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x4),
            child: Text(
              strings.scheduleDragHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
          // One section per day.
          for (final day in week) ...[
            _DaySection(day: day, now: now),
            const SizedBox(height: AppSpacing.x4),
          ],
        ],
      ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  const _DaySection({required this.day, required this.now});

  final AgendaDay day;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final isToday = dateOnly(day.date) == dateOnly(now);

    return DragTarget<TaskOccurrence>(
      onAcceptWithDetails: (details) async {
        final occ = details.data;
        if (dateOnly(occ.scheduledDate) == dateOnly(day.date)) return;
        final svc = ref.read(occurrenceServiceProvider);
        if (svc == null) return;
        await svc.moveTo(occ, day.date);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${strings.movedToDay} ${weekdayLong(day.date)}'),
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isHovering ? AppColors.brandSoft : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: isHovering ? AppColors.brand : AppColors.borderDefault,
              width: isHovering ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day header row.
              Row(
                children: [
                  Text(
                    '${weekdayShort(day.date)} ${day.date.day}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (isToday) ...[
                    const SizedBox(width: AppSpacing.x2),
                    AppChip(
                      label: strings.todayLabelShort,
                      tone: AppChipTone.today,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.x3),
              // Occurrence list or empty state.
              if (day.occurrences.isEmpty)
                Text(
                  strings.scheduleEmptyDay,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                )
              else
                for (final occ in day.occurrences)
                  _OccurrenceRow(occurrence: occ),
            ],
          ),
        );
      },
    );
  }
}

class _OccurrenceRow extends ConsumerWidget {
  const _OccurrenceRow({required this.occurrence});

  final TaskOccurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskByIdProvider(occurrence.taskId));
    final title = task?.title ?? occurrence.taskId;
    final effort = task?.estimatedEffortMinutes ?? 0;

    // Done occurrences are shown for context but must not be draggable — moving
    // one would flip it back to "rescheduled" (open) and silently undo the
    // completion. Only open occurrences can be dragged to another day.
    if (!occurrence.isOpen) {
      return _RowContent(title: title, effort: effort, done: true);
    }

    return LongPressDraggable<TaskOccurrence>(
      data: occurrence,
      delay: const Duration(milliseconds: 400),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x3,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _RowContent(title: title, effort: effort),
      ),
      child: _RowContent(title: title, effort: effort),
    );
  }
}

class _RowContent extends StatelessWidget {
  const _RowContent({
    required this.title,
    required this.effort,
    this.done = false,
  });

  final String title;
  final int effort;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: done ? AppColors.textMuted : null,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          AppBadge(label: '~${effort}m'),
          const SizedBox(width: AppSpacing.x2),
          Icon(
            done ? AppIcons.check : AppIcons.dragHandle,
            size: 18,
            color: done ? AppColors.brand : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
