import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/schedule.dart';
import 'db_provider.dart';

final schedulesStreamProvider = StreamProvider<List<Schedule>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.schedules.where().sortByStartTime().watch(fireImmediately: true);
});

class ScheduleController {
  ScheduleController(this._isar);
  final Isar _isar;

  Future<int> addSchedule({
    required String title,
    required DateTime start,
    required DateTime end,
    String? note,
  }) {
    final schedule = Schedule()
      ..title = title
      ..startTime = start
      ..endTime = end
      ..note = note;
    return _isar.writeTxn(() => _isar.schedules.put(schedule));
  }

  Future<void> updateSchedule(Schedule schedule) {
    return _isar.writeTxn(() => _isar.schedules.put(schedule));
  }

  Future<void> deleteSchedule(int id) {
    return _isar.writeTxn(() => _isar.schedules.delete(id));
  }
}

final scheduleControllerProvider = Provider<ScheduleController>((ref) {
  return ScheduleController(ref.watch(isarProvider));
});
