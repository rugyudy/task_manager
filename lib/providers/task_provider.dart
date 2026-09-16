import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/task.dart';
import 'db_provider.dart';
import 'notification_provider.dart';

/// タスク一覧を監視するストリーム。DB が更新された瞬間に自動で再描画される。
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.tasks.where().sortByCreatedAtDesc().watch(fireImmediately: true);
});

class TaskController {
  TaskController(this._isar, this._reminders);
  final Isar _isar;
  final ReminderService _reminders;

  Future<int> addTask(
    String title, {
    DateTime? dueDate,
    List<String> tags = const [],
    int? reminderMinutesBefore,
  }) async {
    final task = Task()
      ..title = title
      ..dueDate = dueDate
      ..tags = tags
      ..reminderMinutesBefore = reminderMinutesBefore;
    final id = await _isar.writeTxn(() => _isar.tasks.put(task));
    await _syncReminder(task);
    return id;
  }

  Future<void> updateTask(Task task) async {
    await _isar.writeTxn(() => _isar.tasks.put(task));
    await _syncReminder(task);
  }

  Future<void> toggleCompleted(Task task) async {
    task.isCompleted = !task.isCompleted;
    await _isar.writeTxn(() => _isar.tasks.put(task));
    await _syncReminder(task);
  }

  Future<void> deleteTask(int id) async {
    await _isar.writeTxn(() => _isar.tasks.delete(id));
    await _reminders.cancel(id);
  }

  Future<void> _syncReminder(Task task) async {
    final dueDate = task.dueDate;
    final minutesBefore = task.reminderMinutesBefore;
    if (task.isCompleted || dueDate == null || minutesBefore == null) {
      await _reminders.cancel(task.id);
      return;
    }
    await _reminders.scheduleAt(
      id: task.id,
      title: 'タスクの期限',
      body: task.title,
      dateTime: dueDate.subtract(Duration(minutes: minutesBefore)),
    );
  }
}

final taskControllerProvider = Provider<TaskController>((ref) {
  return TaskController(ref.watch(isarProvider), ref.watch(reminderServiceProvider));
});
