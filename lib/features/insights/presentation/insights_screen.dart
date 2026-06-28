import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/strings/app_strings.dart';
import '../../settings/application/settings_providers.dart';
import '../../tasks/application/tasks_providers.dart';
import '../../tasks/domain/task.dart';
import '../application/insights_providers.dart';
import '../domain/insights.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightsPeriod _period = InsightsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final occurrences = ref.watch(occurrencesProvider).value ?? [];
    final tasks = ref.watch(tasksProvider).value ?? [];
    final theme = Theme.of(context);

    final s = ref.watch(insightsSummaryProvider(_period));

    return Scaffold(
      appBar: AppBar(title: Text(strings.insightsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          // ── Period toggle ─────────────────────────────────────────────────
          Center(
            child: AppSegmentedControl<InsightsPeriod>(
              segments: [
                AppSegment(
                  value: InsightsPeriod.week,
                  label: strings.periodWeek,
                ),
                AppSegment(
                  value: InsightsPeriod.month,
                  label: strings.periodMonth,
                ),
                AppSegment(
                  value: InsightsPeriod.year,
                  label: strings.periodYear,
                ),
              ],
              value: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
          ),

          const SizedBox(height: AppSpacing.x4),

          // ── Empty state ───────────────────────────────────────────────────
          if (occurrences.isEmpty) ...[
            const SizedBox(height: AppSpacing.x9),
            Center(
              child: Text(
                strings.insightsEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ] else ...[
            // ── Stats card ────────────────────────────────────────────────
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCell(
                    label: strings.completionRateLabel,
                    value: '${(s.completionRate * 100).round()}%',
                  ),
                  _Divider(),
                  _StatCell(
                    label: strings.streakLabel,
                    value: '${s.streakDays}',
                    icon: AppIcons.sun,
                  ),
                  _Divider(),
                  _StatCell(
                    label: strings.timeSpentLabel,
                    value: '${s.totalMinutes}m',
                    mono: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.x4),

            // ── Completion chart ───────────────────────────────────────────
            AppCard(child: _BucketChart(buckets: s.buckets)),

            const SizedBox(height: AppSpacing.x4),

            // ── Slips card ─────────────────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.slipsHeading,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  if (s.slips.isEmpty)
                    Text(strings.noSlips, style: theme.textTheme.bodyMedium)
                  else
                    Column(
                      children: [
                        for (final slip in s.slips) ...[
                          _SlipRow(slip: slip),
                          if (slip != s.slips.last)
                            const SizedBox(height: AppSpacing.x3),
                        ],
                      ],
                    ),
                ],
              ),
            ),

            // ── Suggestion card ────────────────────────────────────────────
            if (s.suggestion != null) ...[
              const SizedBox(height: AppSpacing.x4),
              _SuggestionCard(suggestion: s.suggestion!, tasks: tasks),
            ],

            const SizedBox(height: AppSpacing.x11),
          ],
        ],
      ),
    );
  }
}

// ── Stat cell ──────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.icon,
    this.mono = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mono)
              Text(
                value,
                style: AppTypography.mono(
                  size: AppTypography.h2,
                  weight: AppTypography.bold,
                  color: AppColors.textPrimary,
                ),
              )
            else
              Text(value, style: theme.textTheme.headlineMedium),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: AppColors.today),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Divider ────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.borderSubtle);
  }
}

// ── Bucket bar chart ───────────────────────────────────────────────────────────

class _BucketChart extends StatelessWidget {
  const _BucketChart({required this.buckets});

  final List<InsightBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxCount = buckets.fold<int>(0, (m, b) => max(m, b.doneCount));
    const maxBarHeight = 80.0;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final bucket in buckets)
            _BucketBar(
              bucket: bucket,
              maxCount: maxCount,
              maxBarHeight: maxBarHeight,
            ),
        ],
      ),
    );
  }
}

class _BucketBar extends StatelessWidget {
  const _BucketBar({
    required this.bucket,
    required this.maxCount,
    required this.maxBarHeight,
  });

  final InsightBucket bucket;
  final int maxCount;
  final double maxBarHeight;

  @override
  Widget build(BuildContext context) {
    final h = maxCount == 0
        ? 0.0
        : (bucket.doneCount / maxCount) * maxBarHeight;
    final barH = h.clamp(2.0, maxBarHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bucket.doneCount > 0)
          Text(
            '${bucket.doneCount}',
            style: AppTypography.mono(size: AppTypography.size2xs),
          )
        else
          const SizedBox(height: 14),
        const SizedBox(height: 2),
        Container(
          width: 18,
          height: barH,
          decoration: BoxDecoration(
            color: bucket.doneCount > 0 ? AppColors.brand : AppColors.ink100,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xs),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          bucket.label,
          style: AppTypography.mono(size: AppTypography.size2xs),
        ),
      ],
    );
  }
}

// ── Suggestion card ───────────────────────────────────────────────────────────

/// Renders the adaptive suggestion card, building the human-readable message
/// in the presentation layer (FIX 10: message no longer lives in the domain).
class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.suggestion, required this.tasks});

  final AdaptiveSuggestion suggestion;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    // Resolve task title from the already-loaded tasks list.
    Task? task;
    for (final t in tasks) {
      if (t.id == suggestion.taskId) {
        task = t;
        break;
      }
    }
    final title = (task != null && task.title.isNotEmpty)
        ? task.title
        : 'This task';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.suggestionHeading, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.x2),
          Text(
            '$title ${strings.suggestionTail}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x4),
          AppButton(
            label: strings.suggestionApply,
            variant: AppButtonVariant.tonal,
            onPressed: () => _applySuggestion(context, ref, strings),
          ),
        ],
      ),
    );
  }

  Future<void> _applySuggestion(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final task = ref.read(taskByIdProvider(suggestion.taskId));
    final service = ref.read(taskServiceProvider);
    // Null-check the service explicitly: `?.updateTask(...)` would short-circuit
    // to null when there's no owner, and `await null` doesn't throw — so the
    // catch wouldn't fire and we'd show a false "applied" with nothing written.
    if (task == null || service == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.updateTask(
        task.copyWith(recurrence: suggestion.suggestedRecurrence),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.actionFailed)));
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(strings.suggestionApplied)));
  }
}

// ── Slip row ──────────────────────────────────────────────────────────────────

class _SlipRow extends ConsumerWidget {
  const _SlipRow({required this.slip});

  final TaskSlip slip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskByIdProvider(slip.taskId));
    final strings = ref.watch(appStringsProvider);
    final title = task?.title ?? '—';
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: AppSpacing.x2),
        AppChip(
          label: '${slip.skips}× ${strings.skippedLabel}',
          tone: AppChipTone.reschedule,
        ),
      ],
    );
  }
}
