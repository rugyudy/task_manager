import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widget_catalog.dart';
import '../../providers/layout_provider.dart';
import 'widgets/pane_tile.dart';
import 'widgets/tiling_layout.dart';
import 'widgets/widget_picker.dart';

const _wideBreakpoint = 900.0;

/// 「タスク」「スケジュール」「メモ」などを1画面で俯瞰できるホーム画面。
/// 画面幅が広い場合はIDEのように分割・ドラッグ移動・リサイズできるタイリング
/// レイアウト、狭い場合はツリーを上から順に並べた縦積みリストになる。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        return Scaffold(
          body: isWide ? const TilingLayout() : const _NarrowHome(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final currentTypes = allTypesIn(ref.read(homeLayoutProvider).value);
              final available = allWidgetTypes.where((t) => !currentTypes.contains(t)).toList();
              final chosen = await showWidgetPicker(context, available);
              if (chosen != null) {
                ref.read(homeLayoutProvider.notifier).addWidget(chosen);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('追加'),
          ),
        );
      },
    );
  }
}

/// スマホ向け: タイリングツリーを上から順に並べた縦積みリスト（並び替えは非対応、
/// 追加・削除はデスクトップと共通のデータで反映される）。
class _NarrowHome extends ConsumerWidget {
  const _NarrowHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(homeLayoutProvider);

    return layoutAsync.when(
      data: (root) {
        final leaves = flattenLeaves(root);
        if (leaves.isEmpty) {
          return const Center(child: Text('ホーム画面には何も配置されていません'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: leaves.length,
          itemBuilder: (context, index) {
            final type = leaves[index];
            final route = routeFor(type);
            return SizedBox(
              height: 340,
              child: PaneTile(
                widgetType: type,
                onExpand: route != null ? () => context.go(route) : null,
                trailing: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: '削除',
                    onPressed: () => ref.read(homeLayoutProvider.notifier).removeWidget(type),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }
}
