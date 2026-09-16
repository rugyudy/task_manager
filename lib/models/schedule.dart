import 'package:isar/isar.dart';

part 'schedule.g.dart';

@collection
class Schedule {
  Id id = Isar.autoIncrement;

  late String title;

  @Index()
  late DateTime startTime;

  late DateTime endTime;

  String? note;

  List<String> tags = [];

  /// 開始時刻の何分前に通知するか。null の場合は通知しない。
  int? reminderMinutesBefore;
}
