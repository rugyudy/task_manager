import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/schedule_provider.dart';
import '../../../providers/task_provider.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class StatsPane extends ConsumerWidget {
  const StatsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final schedulesAsync = ref.watch(schedulesStreamProvider);

    return tasksAsync.when(
      data: (tasks) {
        final schedules = schedulesAsync.value ?? const [];
        final completed = tasks.where((t) => t.isCompleted).length;
        final total = tasks.length;
        final ratio = total == 0 ? 0.0 : completed / total;
        final now = DateTime.now();
        final todayTasks =
            tasks.where((t) => t.dueDate != null && _isSameDay(t.dueDate!, now)).length;
        final todaySchedules = schedules.where((s) => _isSameDay(s.startTime, now)).length;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('タスク完了率', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: ratio, minHeight: 10),
              ),
              const SizedBox(height: 4),
              Text('$completed / $total 件完了', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatTile(label: '今日期限のタスク', value: '$todayTasks')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatTile(label: '今日の予定', value: '$todaySchedules')),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
