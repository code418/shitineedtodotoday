import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/strings/app_strings.dart';
import '../../../features/settings/application/settings_providers.dart';
import '../../tasks/application/tasks_providers.dart';
import '../../tasks/domain/scheduling/task_occurrence.dart';
import '../../tasks/domain/task.dart';
import '../application/household_providers.dart';
import '../domain/assignments.dart';
import '../domain/household.dart';

/// Stable id used to represent "You" (the owner) as an assignee.
const _youId = 'you';

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final household = ref.watch(householdProvider).value ?? Household.empty;
    final controller = ref.watch(householdControllerProvider);
    final checklist = ref.watch(todayChecklistProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.householdTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          // --- Members card ---
          _MembersCard(
            strings: strings,
            household: household,
            controller: controller,
          ),
          const SizedBox(height: AppSpacing.x4),

          // --- Today's turns card ---
          _TurnsCard(
            strings: strings,
            household: household,
            checklist: checklist,
            ref: ref,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Members card
// ---------------------------------------------------------------------------

class _MembersCard extends StatelessWidget {
  const _MembersCard({
    required this.strings,
    required this.household,
    required this.controller,
  });

  final AppStrings strings;
  final Household household;
  final HouseholdController? controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.householdMembersHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x4),
          if (household.members.isEmpty)
            Text(
              strings.householdEmpty,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            )
          else
            Wrap(
              spacing: AppSpacing.x4,
              runSpacing: AppSpacing.x3,
              children: [
                // Implicit "You" first.
                _MemberTile(name: strings.youLabel, canRemove: false),
                for (final m in household.members)
                  _MemberTile(
                    name: m.name,
                    canRemove: true,
                    onRemove: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await controller?.removeMember(household, m.id);
                      } catch (_) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(strings.actionFailed)),
                        );
                      }
                    },
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.x4),
          AppButton(
            label: strings.addMemberCta,
            variant: AppButtonVariant.tonal,
            icon: AppIcons.add,
            onPressed: () => _showAddMemberSheet(context),
          ),
        ],
      ),
    );
  }

  void _showAddMemberSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddMemberSheet(
        strings: strings,
        onAdd: (name) async {
          await controller?.addMember(household, name);
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.name,
    required this.canRemove,
    this.onRemove,
  });

  final String name;
  final bool canRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppAvatar(name: name, size: 44),
        const SizedBox(height: AppSpacing.x1),
        if (canRemove)
          GestureDetector(
            onLongPress: onRemove,
            child: Text(name, style: Theme.of(context).textTheme.labelMedium),
          )
        else
          Text(name, style: Theme.of(context).textTheme.labelMedium),
        if (canRemove)
          AppIconButton(
            icon: AppIcons.close,
            size: 28,
            tooltip: 'Remove $name',
            onPressed: onRemove,
          ),
      ],
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.strings, required this.onAdd});

  final AppStrings strings;
  final Future<void> Function(String name) onAdd;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppLayout.screenPad,
        right: AppLayout.screenPad,
        top: AppSpacing.x6,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.x6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: widget.strings.memberNameHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(context),
          ),
          const SizedBox(height: AppSpacing.x4),
          AppButton(
            label: widget.strings.addMemberCta,
            block: true,
            onPressed: () => _submit(context),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    try {
      await widget.onAdd(name);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(widget.strings.actionFailed)),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Today's turns card
// ---------------------------------------------------------------------------

class _TurnsCard extends StatelessWidget {
  const _TurnsCard({
    required this.strings,
    required this.household,
    required this.checklist,
    required this.ref,
  });

  final AppStrings strings;
  final Household household;
  final List<TaskOccurrence> checklist;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    // Build assignee map: taskId → assigneeId.
    final assigneeByTaskId = <String, String?>{
      for (final o in checklist)
        o.taskId: ref.watch(taskByIdProvider(o.taskId))?.assigneeId,
    };
    // Ids that have their own bucket below; anything else (e.g. a task still
    // assigned to a removed member) folds into the visible "anyone" bucket.
    final knownIds = {_youId, for (final m in household.members) m.id};
    final groups = assignmentsByMember(
      checklist,
      assigneeByTaskId,
      knownAssigneeIds: knownIds,
    );

    // Render order: you → members → anyone (null key).
    final buckets = <(String?, String)>[
      (_youId, strings.youLabel),
      for (final m in household.members) (m.id, m.name),
      (null, strings.unassignedLabel),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.whoseTurnHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final (id, label) in buckets)
            if (groups.containsKey(id)) ...[
              const SizedBox(height: AppSpacing.x4),
              _BucketSection(
                label: label,
                occurrences: groups[id]!,
                strings: strings,
                household: household,
                ref: ref,
              ),
            ],
          if (groups.isEmpty) ...[
            const SizedBox(height: AppSpacing.x3),
            Text(
              strings.householdEmpty,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _BucketSection extends StatelessWidget {
  const _BucketSection({
    required this.label,
    required this.occurrences,
    required this.strings,
    required this.household,
    required this.ref,
  });

  final String label;
  final List<TaskOccurrence> occurrences;
  final AppStrings strings;
  final Household household;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppChip(label: label, tone: AppChipTone.brand),
        const SizedBox(height: AppSpacing.x2),
        for (final o in occurrences)
          _TurnRow(
            occurrence: o,
            strings: strings,
            household: household,
            ref: ref,
          ),
      ],
    );
  }
}

class _TurnRow extends StatelessWidget {
  const _TurnRow({
    required this.occurrence,
    required this.strings,
    required this.household,
    required this.ref,
  });

  final TaskOccurrence occurrence;
  final AppStrings strings;
  final Household household;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskByIdProvider(occurrence.taskId));
    final title = task?.title ?? occurrence.taskId;

    return InkWell(
      onTap: task == null ? null : () => _showReassignSheet(context, task),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Icon(AppIcons.edit, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showReassignSheet(BuildContext context, Task task) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _ReassignSheet(
        strings: strings,
        task: task,
        household: household,
        ref: ref,
      ),
    );
  }
}

class _ReassignSheet extends StatelessWidget {
  const _ReassignSheet({
    required this.strings,
    required this.task,
    required this.household,
    required this.ref,
  });

  final AppStrings strings;
  final Task task;
  final Household household;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final options = <(String?, String)>[
      (_youId, strings.youLabel),
      for (final m in household.members) (m.id, m.name),
      (null, strings.unassignedLabel),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.screenPad,
              AppSpacing.x5,
              AppLayout.screenPad,
              AppSpacing.x3,
            ),
            child: Text(
              strings.reassignTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final (id, label) in options)
            ListTile(
              leading: AppAvatar(name: label, size: 36),
              title: Text(label),
              selected: task.assigneeId == id,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final taskService = ref.read(taskServiceProvider);
                Navigator.of(context).pop();
                if (taskService == null) return;
                try {
                  await taskService.updateTask(task.copyWith(assigneeId: id));
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(strings.actionFailed)),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
