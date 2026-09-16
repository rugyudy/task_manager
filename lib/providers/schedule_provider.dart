import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/schedule.dart';
import 'db_provider.dart';
import 'notification_provider.dart';

final schedulesStreamProvider = StreamProvider<List<Schedule>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.schedules.where().sortByStartTime().watch(fireImmediately: true);
});

class ScheduleController {
  ScheduleController(this._isar, this._reminders);
  final Isar _isar;
  final ReminderService _reminders;

  Future<int> addSchedule({
    required String title,
    required DateTime start,
    required DateTime end,
    String? note,
    List<String> tags = const [],
    int? reminderMinutesBefore,
  }) async {
    final schedule = Schedule()
      ..title = title
      ..startTime = start
      ..endTime = end
      ..note = note
      ..tags = tags
      ..reminderMinutesBefore = reminderMinutesBefore;
    final id = await _isar.writeTxn(() => _isar.schedules.put(schedule));
    await _syncReminder(schedule);
    return id;
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _isar.writeTxn(() => _isar.schedules.put(schedule));
    await _syncReminder(schedule);
  }

  Future<void> deleteSchedule(int id) async {
    await _isar.writeTxn(() => _isar.schedules.delete(id));
    await _reminders.cancel(id + scheduleNotificationIdOffset);
  }

  Future<void> _syncReminder(Schedule schedule) async {
    final minutesBefore = schedule.reminderMinutesBefore;
    final notificationId = schedule.id + scheduleNotificationIdOffset;
    if (minutesBefore == null) {
      await _reminders.cancel(notificationId);
      return;
    }
    await _reminders.scheduleAt(
      id: notificationId,
      title: '予定の開始',
      body: schedule.title,
      dateTime: schedule.startTime.subtract(Duration(minutes: minutesBefore)),
    );
  }
}

final scheduleControllerProvider = Provider<ScheduleController>((ref) {
  return ScheduleController(ref.watch(isarProvider), ref.watch(reminderServiceProvider));
});
