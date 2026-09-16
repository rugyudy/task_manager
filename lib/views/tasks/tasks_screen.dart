import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/reminder_picker.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/tag_editor.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _hideCompleted = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> _filter(List<Task> tasks) {
    final query = _searchController.text.trim().toLowerCase();
    return tasks.where((task) {
      if (_hideCompleted && task.isCompleted) return false;
      if (query.isNotEmpty && !task.title.toLowerCase().contains(query)) return false;
      if (_selectedTags.isNotEmpty && !_selectedTags.every(task.tags.contains)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _showTaskDialog({Task? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    var dueDate = task?.dueDate;
    var tags = List<String>.from(task?.tags ?? const []);
    var reminderMinutesBefore = task?.reminderMinutesBefore;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(task == null ? '新しいタスク' : 'タスクを編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (dueDate != null) ...[
                      const SizedBox(height: 4),
                      ReminderPicker(
                        value: reminderMinutesBefore,
                        onChanged: (value) =>
                            setState(() => reminderMinutesBefore = value),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TagEditor(
                      tags: tags,
                      onChanged: (updated) => setState(() => tags = updated),
                    ),
                  ],
                ),
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
                      controller.addTask(
                        title,
                        dueDate: dueDate,
                        tags: tags,
                        reminderMinutesBefore: dueDate == null ? null : reminderMinutesBefore,
                      );
                    } else {
                      task
                        ..title = title
                        ..dueDate = dueDate
                        ..tags = tags
                        ..reminderMinutesBefore = dueDate == null ? null : reminderMinutesBefore;
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
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      body: tasksAsync.when(
        data: (tasks) {
          final allTags = tasks.expand((t) => t.tags).toSet().toList()..sort();
          final filtered = _filter(tasks);

          return Column(
            children: [
              SearchFilterBar(
                searchController: _searchController,
                allTags: allTags,
                selectedTags: _selectedTags,
                onTagToggled: (tag) => setState(() {
                  if (!_selectedTags.remove(tag)) _selectedTags.add(tag);
                }),
                extraFilter: FilterChip(
                  label: const Text('完了を隠す'),
                  selected: _hideCompleted,
                  onSelected: (v) => setState(() => _hideCompleted = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('該当するタスクがありません'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final task = filtered[index];
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
                                    ? const TextStyle(
                                        decoration: TextDecoration.lineThrough)
                                    : null,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (task.dueDate != null)
                                    Text(
                                        '期限: ${task.dueDate!.toLocal()}'.split(' ').first),
                                  if (task.tags.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 4,
                                        children: [
                                          for (final tag in task.tags)
                                            Chip(
                                              label: Text(
                                                tag,
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                              visualDensity: VisualDensity.compact,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize.shrinkWrap,
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              secondary: IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showTaskDialog(task: task),
                              ),
                              onChanged: (_) =>
                                  ref.read(taskControllerProvider).toggleCompleted(task),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
