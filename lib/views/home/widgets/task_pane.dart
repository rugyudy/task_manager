import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/task_provider.dart';
import 'pane_card.dart';

class TaskPane extends ConsumerWidget {
  const TaskPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);

    return PaneCard(
      title: 'タスク',
      icon: Icons.check_circle_outline,
      onExpand: () => context.go('/tasks'),
      child: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('タスクはありません'));
          }
          final visible = tasks.take(20).toList();
          return ListView.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final task = visible[index];
              return CheckboxListTile(
                dense: true,
                value: task.isCompleted,
                title: Text(
                  task.title,
                  style: task.isCompleted
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                subtitle: task.dueDate != null
                    ? Text('期限: ${task.dueDate!.toLocal()}'.split(' ').first)
                    : null,
                onChanged: (_) =>
                    ref.read(taskControllerProvider).toggleCompleted(task),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }
}
