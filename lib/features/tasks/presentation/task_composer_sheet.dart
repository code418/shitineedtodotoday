import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/util/date_labels.dart';
import '../../settings/application/settings_providers.dart';
import '../application/tasks_providers.dart';
import '../domain/scheduling/recurrence.dart';
import '../domain/task.dart';

enum _RecurrencePreset { weekdays, weekly, monthly, everyday, seasonal, oneOff }

const _seasonLabels = ['Spring', 'Summer', 'Autumn', 'Winter'];

/// Shows the add/edit task modal bottom sheet.
///
/// Pass [existing] to pre-fill the form for editing; omit to open a blank
/// "new task" form. Awaiting the returned future resolves once the sheet
/// is dismissed (whether saved or cancelled).
Future<void> showTaskComposer(BuildContext context, {Task? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TaskComposerSheet(existing: existing),
  );
}

class _TaskComposerSheet extends ConsumerStatefulWidget {
  const _TaskComposerSheet({this.existing});

  final Task? existing;

  @override
  ConsumerState<_TaskComposerSheet> createState() => _TaskComposerSheetState();
}

class _TaskComposerSheetState extends ConsumerState<_TaskComposerSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _categoryCtrl;
  late int _effort;
  late _RecurrencePreset _preset;
  late Set<int> _selectedWeekdays;
  Season _season = Season.summer;
  DateTime? _exactDate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _categoryCtrl = TextEditingController(text: existing?.category ?? '');
    _effort = (existing?.estimatedEffortMinutes ?? 15).clamp(5, 120);

    if (existing != null) {
      final rec = existing.recurrence;
      if (rec is StrictRecurrence && rec.exactDate != null) {
        _preset = _RecurrencePreset.oneOff;
        _exactDate = rec.exactDate;
        _selectedWeekdays = {};
      } else if (rec is StrictRecurrence && rec.weekdays.isNotEmpty) {
        _preset = _RecurrencePreset.weekdays;
        _selectedWeekdays = rec.weekdays.toSet();
      } else if (rec is FlexibleRecurrence && rec.season != null) {
        _preset = _RecurrencePreset.seasonal;
        _season = rec.season!;
        _selectedWeekdays = {};
      } else if (rec is FlexibleRecurrence) {
        switch (rec.period) {
          case FrequencyPeriod.week:
            _preset = _RecurrencePreset.weekly;
            _selectedWeekdays = {};
          case FrequencyPeriod.month:
            _preset = _RecurrencePreset.monthly;
            _selectedWeekdays = {};
          case FrequencyPeriod.day:
            _preset = _RecurrencePreset.everyday;
            _selectedWeekdays = {};
          case FrequencyPeriod.year:
            _preset = _RecurrencePreset.weekdays;
            _selectedWeekdays = {ref.read(clockProvider)().weekday};
        }
      } else {
        _preset = _RecurrencePreset.weekdays;
        _selectedWeekdays = {ref.read(clockProvider)().weekday};
      }
    } else {
      _preset = _RecurrencePreset.weekdays;
      _selectedWeekdays = {ref.read(clockProvider)().weekday};
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final strings = ref.read(appStringsProvider);
    final title = _titleCtrl.text.trim();
    final category = _categoryCtrl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.titleRequired)));
      return;
    }

    if (_preset == _RecurrencePreset.weekdays && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.pickADay)));
      return;
    }

    if (_preset == _RecurrencePreset.oneOff && _exactDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.pickADate)));
      return;
    }

    final svc = ref.read(taskServiceProvider);
    if (svc == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.firebaseNotConfigured)));
      return;
    }

    final recurrence = _buildRecurrence();
    final isNew = widget.existing == null;

    try {
      if (isNew) {
        await svc.addTask(
          title: title,
          recurrence: recurrence,
          category: category.isEmpty ? null : category,
          estimatedEffortMinutes: _effort,
        );
      } else {
        await svc.updateTask(
          widget.existing!.copyWith(
            title: title,
            category: category.isEmpty ? null : category,
            recurrence: recurrence,
            estimatedEffortMinutes: _effort,
          ),
        );
      }
    } catch (_) {
      // Keep the sheet open so the user can retry without re-entering details.
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.actionFailed)));
      return;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    if (isNew) {
      messenger.showSnackBar(SnackBar(content: Text(strings.taskAdded)));
    }
  }

  Recurrence _buildRecurrence() {
    return switch (_preset) {
      _RecurrencePreset.weekdays => Recurrence.strict(
        weekdays: _selectedWeekdays.toList()..sort(),
      ),
      _RecurrencePreset.weekly => const Recurrence.flexible(
        period: FrequencyPeriod.week,
      ),
      _RecurrencePreset.monthly => const Recurrence.flexible(
        period: FrequencyPeriod.month,
      ),
      _RecurrencePreset.everyday => const Recurrence.flexible(
        period: FrequencyPeriod.day,
      ),
      _RecurrencePreset.seasonal => Recurrence.flexible(season: _season),
      _RecurrencePreset.oneOff => Recurrence.strict(exactDate: _exactDate),
    };
  }

  String _formatDate(DateTime d) => dayMonthYear(d);

  String _presetLabel(_RecurrencePreset preset, AppStrings strings) {
    return switch (preset) {
      _RecurrencePreset.weekdays => strings.recurrenceWeekdays,
      _RecurrencePreset.weekly => strings.recurrenceWeekly,
      _RecurrencePreset.monthly => strings.recurrenceMonthly,
      _RecurrencePreset.everyday => strings.recurrenceEveryday,
      _RecurrencePreset.seasonal => strings.recurrenceSeasonal,
      _RecurrencePreset.oneOff => strings.recurrenceOneOff,
    };
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? strings.composerNewTitle
                        : strings.composerEditTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x4),

            // Title field
            Text(
              strings.composerTitleLabel,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.x1),
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: strings.composerTitleHint,
                filled: true,
                fillColor: AppColors.surfaceSunken,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),

            // Category field
            Text(
              strings.composerCategoryLabel,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.x1),
            TextField(
              controller: _categoryCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: strings.composerCategoryHint,
                filled: true,
                fillColor: AppColors.surfaceSunken,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),

            // Effort slider
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.composerEffortLabel,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                AppBadge(label: '~${_effort}m', tone: AppBadgeTone.brand),
              ],
            ),
            Slider(
              min: 5,
              max: 120,
              divisions: 23,
              value: _effort.toDouble(),
              onChanged: (v) => setState(() => _effort = v.round()),
            ),
            const SizedBox(height: AppSpacing.x4),

            // Recurrence preset chips
            Text(
              strings.composerRecurrenceLabel,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                for (final preset in _RecurrencePreset.values)
                  AppChip(
                    label: _presetLabel(preset, strings),
                    selectable: true,
                    selected: _preset == preset,
                    onTap: () => setState(() => _preset = preset),
                  ),
              ],
            ),

            // Weekday chips (shown only when "Specific days" is selected)
            if (_preset == _RecurrencePreset.weekdays) ...[
              const SizedBox(height: AppSpacing.x2),
              Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x2,
                children: [
                  for (int i = 0; i < 7; i++)
                    AppChip(
                      label: kWeekdayNamesShort[i],
                      selectable: true,
                      selected: _selectedWeekdays.contains(i + 1),
                      onTap: () => setState(() {
                        final day = i + 1;
                        if (_selectedWeekdays.contains(day)) {
                          _selectedWeekdays.remove(day);
                        } else {
                          _selectedWeekdays.add(day);
                        }
                      }),
                    ),
                ],
              ),
            ],

            // Season chips (shown only when "Seasonal" is selected)
            if (_preset == _RecurrencePreset.seasonal) ...[
              const SizedBox(height: AppSpacing.x2),
              Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x2,
                children: [
                  for (int i = 0; i < _seasonLabels.length; i++)
                    AppChip(
                      label: _seasonLabels[i],
                      selectable: true,
                      selected: _season == Season.values[i],
                      onTap: () => setState(() => _season = Season.values[i]),
                    ),
                ],
              ),
            ],

            // Date picker button (shown only when "One-off" is selected)
            if (_preset == _RecurrencePreset.oneOff) ...[
              const SizedBox(height: AppSpacing.x2),
              AppButton(
                variant: AppButtonVariant.tonal,
                label: _exactDate == null
                    ? strings.chooseDate
                    : _formatDate(_exactDate!),
                onPressed: () async {
                  final now = ref.read(clockProvider)();
                  final firstDate = DateTime(now.year, now.month, now.day);
                  // When editing a one-off whose date has already passed,
                  // _exactDate is before firstDate — clamp it so showDatePicker's
                  // (initialDate >= firstDate) assertion can't fire.
                  final initialDate =
                      (_exactDate != null && !_exactDate!.isBefore(firstDate))
                      ? _exactDate!
                      : firstDate;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) setState(() => _exactDate = picked);
                },
              ),
            ],

            const SizedBox(height: AppSpacing.x5),
            AppButton(
              label: strings.composerSave,
              block: true,
              pill: true,
              onPressed: _onSave,
            ),
            const SizedBox(height: AppSpacing.x2),
          ],
        ),
      ),
    );
  }
}
