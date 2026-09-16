import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/task.dart';
import 'db_provider.dart';

/// タスク一覧を監視するストリーム。DB が更新された瞬間に自動で再描画される。
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.tasks.where().sortByCreatedAtDesc().watch(fireImmediately: true);
});

class TaskController {
  TaskController(this._isar);
  final Isar _isar;

  Future<int> addTask(String title, {DateTime? dueDate}) {
    final task = Task()
      ..title = title
      ..dueDate = dueDate;
    return _isar.writeTxn(() => _isar.tasks.put(task));
  }

  Future<void> updateTask(Task task) {
    return _isar.writeTxn(() => _isar.tasks.put(task));
  }

  Future<void> toggleCompleted(Task task) {
    task.isCompleted = !task.isCompleted;
    return _isar.writeTxn(() => _isar.tasks.put(task));
  }

  Future<void> deleteTask(int id) {
    return _isar.writeTxn(() => _isar.tasks.delete(id));
  }
}

final taskControllerProvider = Provider<TaskController>((ref) {
  return TaskController(ref.watch(isarProvider));
});
