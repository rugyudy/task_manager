import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../providers/layout_provider.dart';
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
/// 広い場合は境界線をドラッグしてサイズ変更できる分割ビューになる。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(layoutOrderProvider);

    return orderAsync.when(
      data: (order) => LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;
          return isWide ? _WideHome(order: order) : _NarrowHome(order: order);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }
}

/// スマホ向け: 長押しでドラッグして表示順を入れ替えられる縦積みレイアウト。
class _NarrowHome extends ConsumerWidget {
  const _NarrowHome({required this.order});

  final List<String> order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
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
    );
  }
}

/// タブレット/PC向け: 境界線をドラッグしてサイズを変更できる分割レイアウト。
class _WideHome extends ConsumerWidget {
  const _WideHome({required this.order});

  final List<String> order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightsAsync = ref.watch(layoutWeightsProvider);

    return weightsAsync.when(
      data: (weights) {
        final areas = [
          for (var i = 0; i < order.length; i++)
            Area(weight: i < weights.length ? weights[i] : null),
        ];
        final controller = MultiSplitViewController(areas: areas);

        return Padding(
          padding: const EdgeInsets.all(8),
          child: MultiSplitView(
            controller: controller,
            onWeightChange: () {
              final newWeights = controller.areas
                  .map((a) => a.weight ?? (1 / order.length))
                  .toList();
              ref.read(layoutWeightsProvider.notifier).updateWeights(newWeights);
            },
            children: [for (final key in order) _paneFor(key)],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }
}
