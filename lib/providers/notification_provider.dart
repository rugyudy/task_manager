import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _androidChannel = AndroidNotificationDetails(
  'reminders',
  'リマインダー',
  channelDescription: 'タスク・スケジュールの通知',
  importance: Importance.high,
  priority: Priority.high,
);

/// タスク/スケジュールの通知IDが衝突しないようにするオフセット。
const scheduleNotificationIdOffset = 1000000;

/// タスク・スケジュールの期限/開始時刻をローカル通知でリマインドする仕組み。
class ReminderService {
  ReminderService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Windows など flutter_local_notifications が未対応のプラットフォームでは
  /// 通知機能を無効化してアプリ本体は問題なく動かし続ける。
  bool _supported = true;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      tz_data.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        macOS: iosInit,
      );
      await _plugin.initialize(initSettings);

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      _supported = false;
    }
  }

  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (!_supported) return;
    if (dateTime.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(dateTime, tz.local),
        const NotificationDetails(android: _androidChannel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // 通知のスケジュールに失敗しても、タスク/スケジュール自体の保存は継続する。
    }
  }

  Future<void> cancel(int id) async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  throw UnimplementedError('main() で reminderServiceProvider.overrideWithValue が必要です');
});
