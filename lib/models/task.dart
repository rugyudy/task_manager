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

  List<String> tags = [];

  /// 期限の何分前に通知するか。null の場合は通知しない。
  int? reminderMinutesBefore;

  /// このタスクの作成元となったメモ（メモからの連携用）
  final memo = IsarLink<Memo>();
}
