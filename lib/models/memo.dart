import 'package:isar/isar.dart';

import 'task.dart';

part 'memo.g.dart';

@collection
class Memo {
  Id id = Isar.autoIncrement;

  late String title;

  late String content;

  @Index()
  DateTime updatedAt = DateTime.now();

  List<String> tags = [];

  /// このメモから作成されたタスク一覧（Task.memo の逆リンク）
  @Backlink(to: 'memo')
  final tasks = IsarLinks<Task>();
}
