import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  Future<void> _showTaskDialog(
    BuildContext context,
    WidgetRef ref, {
    Task? task,
  }) {
    final titleController = TextEditingController(text: task?.title ?? '');
    var dueDate = task?.dueDate;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(task == null ? '新しいタスク' : 'タスクを編集'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dueDate == null
                              ? '期限なし'
                              : '期限: ${dueDate!.toLocal()}'.split(' ').first,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 5),
                            ),
                          );
                          if (picked != null) {
                            setState(() => dueDate = picked);
                          }
                        },
                        child: const Text('選択'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    final controller = ref.read(taskControllerProvider);
                    if (task == null) {
                      controller.addTask(title, dueDate: dueDate);
                    } else {
                      task
                        ..title = title
                        ..dueDate = dueDate;
                      controller.updateTask(task);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('タスクがありません。右下の + から追加しましょう。'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: ValueKey(task.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) =>
                    ref.read(taskControllerProvider).deleteTask(task.id),
                child: CheckboxListTile(
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
                  secondary: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showTaskDialog(context, ref, task: task),
                  ),
                  onChanged: (_) =>
                      ref.read(taskControllerProvider).toggleCompleted(task),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
