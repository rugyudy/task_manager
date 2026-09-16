import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'core/theme.dart';
import 'models/memo.dart';
import 'models/schedule.dart';
import 'models/task.dart';
import 'providers/db_provider.dart';
import 'providers/notification_provider.dart';
import 'views/home/home_screen.dart';
import 'views/layout/app_shell.dart';
import 'views/memos/memos_screen.dart';
import 'views/schedules/schedules_screen.dart';
import 'views/tasks/tasks_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [TaskSchema, ScheduleSchema, MemoSchema],
    directory: dir.path,
  );

  final reminders = ReminderService();
  await reminders.init();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        reminderServiceProvider.overrideWithValue(reminders),
      ],
      child: const TaskManagerApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: '/schedules',
          builder: (context, state) => const SchedulesScreen(),
        ),
        GoRoute(
          path: '/memos',
          builder: (context, state) => const MemosScreen(),
        ),
      ],
    ),
  ],
);

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'タスク管理アプリ',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      routerConfig: _router,
    );
  }
}
