import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/schedule_provider.dart';

class SchedulePane extends ConsumerWidget {
  const SchedulePane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesStreamProvider);

    return schedulesAsync.when(
      data: (schedules) {
        final now = DateTime.now();
        final upcoming = schedules.where((s) => s.endTime.isAfter(now)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        if (upcoming.isEmpty) {
          return const Center(child: Text('予定はありません'));
        }
        final visible = upcoming.take(20).toList();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final schedule = visible[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.event_rounded, size: 20),
              title: Text(schedule.title),
              subtitle: Text(
                '${schedule.startTime.toLocal()} - ${schedule.endTime.toLocal()}'
                    .replaceAll(RegExp(r'\.\d+'), ''),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }
}
