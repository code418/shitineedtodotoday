import 'package:flutter/material.dart';

import '../../../features/tasks/presentation/widgets/task_item.dart';
import '../design.dart';

/// Debug-only showcase of the design system: tokens + every widget variant.
/// Linked from Settings in debug builds; useful as living documentation.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _switch = true;
  bool _check = false;
  String _segment = 'week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: [
          const _Section('Brand'),
          const Center(child: AppBrandMark(size: 88)),
          const _Section('Buttons'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(label: 'Primary', onPressed: () {}),
              AppButton(
                label: 'Tonal',
                variant: AppButtonVariant.tonal,
                onPressed: () {},
              ),
              AppButton(
                label: 'Ghost',
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                label: 'Danger',
                variant: AppButtonVariant.danger,
                onPressed: () {},
              ),
              AppButton(
                label: 'Add',
                icon: AppIcons.add,
                pill: true,
                onPressed: () {},
              ),
              const AppButton(label: 'Disabled'),
            ],
          ),
          const _Section('Icon buttons'),
          Row(
            children: [
              AppIconButton(icon: AppIcons.settings, onPressed: () {}),
              const SizedBox(width: 8),
              AppIconButton(
                icon: AppIcons.add,
                tone: AppIconButtonTone.brand,
                onPressed: () {},
              ),
            ],
          ),
          const _Section('Segmented control'),
          AppSegmentedControl<String>(
            value: _segment,
            onChanged: (v) => setState(() => _segment = v),
            segments: const [
              AppSegment(value: 'week', label: 'Week'),
              AppSegment(value: 'month', label: 'Month'),
              AppSegment(value: 'year', label: 'Year'),
            ],
          ),
          const _Section('Chips'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              AppChip(label: 'Neutral'),
              AppChip(label: 'Today', tone: AppChipTone.today),
              AppChip(label: 'Done', tone: AppChipTone.done),
              AppChip(label: 'Moved', tone: AppChipTone.reschedule),
            ],
          ),
          const _Section('Badges'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              AppBadge(label: '~15m'),
              AppBadge(label: '55m', tone: AppBadgeTone.brand),
              AppBadge(label: 'done', tone: AppBadgeTone.done),
            ],
          ),
          const _Section('Progress meter'),
          const AppProgressMeter(value: 30, max: 55, label: "Today's load"),
          const SizedBox(height: 12),
          const AppProgressMeter(value: 70, max: 55, label: 'Over budget'),
          const _Section('Avatars'),
          Row(
            children: const [
              AppAvatar(name: 'Richard Brown'),
              SizedBox(width: 8),
              AppAvatar(name: 'Sam Lee'),
            ],
          ),
          const _Section('Banners'),
          const AppBanner(
            message: 'You are offline',
            tone: AppBannerTone.offline,
          ),
          const SizedBox(height: 8),
          const AppBanner(
            message: 'We moved 2 tasks to a quieter day',
            tone: AppBannerTone.gentle,
          ),
          const _Section('Switch / checkbox'),
          Row(
            children: [
              AppSwitch(
                value: _switch,
                onChanged: (v) => setState(() => _switch = v),
              ),
              const SizedBox(width: 16),
              AppCheckbox(
                value: _check,
                onChanged: (v) => setState(() => _check = v),
              ),
            ],
          ),
          const _Section('Task items'),
          const AppTaskItem(
            title: 'Wash bedding',
            minutes: 10,
            category: 'Kitchen & Bedding',
          ),
          const SizedBox(height: 8),
          const AppTaskItem(
            title: 'Clean toilets',
            minutes: 5,
            category: 'Bathrooms & Mail',
            movedFrom: 'Tuesday',
          ),
          const SizedBox(height: 8),
          const AppTaskItem(title: 'Empty trash', minutes: 10, done: true),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}
