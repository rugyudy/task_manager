import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/layout_provider.dart';
import 'widgets/dashboard_grid.dart';
import 'widgets/memo_pane.dart';
import 'widgets/schedule_pane.dart';
import 'widgets/task_pane.dart';

const _wideBreakpoint = 900.0;

Widget _paneFor(String key) {
  switch (key) {
    case 'tasks':
      return const TaskPane();
    case 'schedules':
      return const SchedulePane();
    case 'memos':
      return const MemoPane();
    default:
      throw ArgumentError('unknown pane: $key');
  }
}

/// 「タスク」「スケジュール」「メモ」を1画面で俯瞰できるホーム画面。
/// 画面幅が狭い場合はドラッグで並び替え可能な縦積みリスト、
/// 広い場合はグリッドに吸着しながら自由に配置・リサイズできるダッシュボードになる。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        return isWide ? const DashboardGrid() : const _NarrowHome();
      },
    );
  }
}

/// スマホ向け: 長押しでドラッグして表示順を入れ替えられる縦積みレイアウト。
class _NarrowHome extends ConsumerWidget {
  const _NarrowHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(layoutOrderProvider);

    return orderAsync.when(
      data: (order) => ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: order.length,
        onReorder: (oldIndex, newIndex) {
          ref.read(layoutOrderProvider.notifier).reorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final key = order[index];
          return SizedBox(
            key: ValueKey(key),
            height: 340,
            child: Stack(
              children: [
                _paneFor(key),
                Positioned(
                  top: 8,
                  right: 4,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }
}
