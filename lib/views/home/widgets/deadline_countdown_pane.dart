import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/schedule.dart';
import '../../../models/task.dart';
import '../../../providers/clock_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/task_provider.dart';

class DeadlineCountdownPane extends ConsumerWidget {
  const DeadlineCountdownPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1分ごとに再描画して「あとX分」の表示を更新するためだけに購読する。
    ref.watch(minuteTickerProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);
    final schedulesAsync = ref.watch(schedulesStreamProvider);

    return tasksAsync.when(
      data: (tasks) {
        final schedules = schedulesAsync.value ?? const <Schedule>[];
        final now = DateTime.now();

        final upcomingTasks = tasks
            .where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isAfter(now))
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
        final Task? nextTask = upcomingTasks.isEmpty ? null : upcomingTasks.first;

        final upcomingSchedules = schedules.where((s) => s.startTime.isAfter(now)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        final Schedule? nextSchedule = upcomingSchedules.isEmpty ? null : upcomingSchedules.first;

        if (nextTask == null && nextSchedule == null) {
          return const Center(child: Text('直近の期限・予定はありません'));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (nextTask != null)
                _CountdownRow(
                  icon: Icons.check_circle_outline,
                  label: nextTask.title,
                  target: nextTask.dueDate!,
                  now: now,
                ),
              if (nextTask != null && nextSchedule != null) const SizedBox(height: 12),
              if (nextSchedule != null)
                _CountdownRow(
                  icon: Icons.event,
                  label: nextSchedule.title,
                  target: nextSchedule.startTime,
                  now: now,
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

class _CountdownRow extends StatelessWidget {
  const _CountdownRow({
    required this.icon,
    required this.label,
    required this.target,
    required this.now,
  });

  final IconData icon;
  final String label;
  final DateTime target;
  final DateTime now;

  String _format() {
    final diff = target.difference(now);
    if (diff.inDays >= 1) return 'あと${diff.inDays}日';
    if (diff.inHours >= 1) return 'あと${diff.inHours}時間';
    if (diff.inMinutes >= 1) return 'あと${diff.inMinutes}分';
    return 'まもなく';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                _format(),
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
