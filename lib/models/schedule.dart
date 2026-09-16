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
}
