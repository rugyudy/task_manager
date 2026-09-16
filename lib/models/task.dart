import 'package:isar/isar.dart';

import 'memo.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  late String title;

  bool isCompleted = false;

  @Index()
  DateTime? dueDate;

  @Index()
  DateTime createdAt = DateTime.now();

  /// このタスクの作成元となったメモ（メモからの連携用）
  final memo = IsarLink<Memo>();
}
