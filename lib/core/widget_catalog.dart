import 'package:flutter/widgets.dart';

import '../views/home/widgets/deadline_countdown_pane.dart';
import '../views/home/widgets/memo_pane.dart';
import '../views/home/widgets/pomodoro_pane.dart';
import '../views/home/widgets/quick_memo_pane.dart';
import '../views/home/widgets/schedule_pane.dart';
import '../views/home/widgets/stats_pane.dart';
import '../views/home/widgets/task_pane.dart';

/// ホーム画面に配置できるウィジェットの全種類。
const allWidgetTypes = <String>[
  'tasks',
  'schedules',
  'memos',
  'pomodoro',
  'stats',
  'quick_memo',
  'deadline_countdown',
];

Widget buildPaneContent(String widgetType) {
  switch (widgetType) {
    case 'tasks':
      return const TaskPane();
    case 'schedules':
      return const SchedulePane();
    case 'memos':
      return const MemoPane();
    case 'pomodoro':
      return const PomodoroPane();
    case 'stats':
      return const StatsPane();
    case 'quick_memo':
      return const QuickMemoPane();
    case 'deadline_countdown':
      return const DeadlineCountdownPane();
    default:
      throw ArgumentError('unknown widget type: $widgetType');
  }
}

/// タップで全画面表示できるウィジェットは、対応する go_router のパスを返す。
/// 全画面用の画面を持たないウィジェット（タイマーなど）は null。
String? routeFor(String widgetType) {
  switch (widgetType) {
    case 'tasks':
      return '/tasks';
    case 'schedules':
      return '/schedules';
    case 'memos':
      return '/memos';
    default:
      return null;
  }
}
