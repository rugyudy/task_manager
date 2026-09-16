import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/pane_style.dart';
import '../../../core/widget_catalog.dart';
import '../../../providers/layout_provider.dart';
import 'pane_tile.dart';
import 'widget_picker.dart';

enum _DropZone { left, right, top, bottom, center }

_DropZone _zoneFor(Offset local, Size size) {
  final dx = local.dx / size.width;
  final dy = local.dy / size.height;
  const edge = 0.25;
  if (dx < edge) return _DropZone.left;
  if (dx > 1 - edge) return _DropZone.right;
  if (dy < edge) return _DropZone.top;
  if (dy > 1 - edge) return _DropZone.bottom;
  return _DropZone.center;
}

/// PC/タブレット向け: IDEのようにペインを左右・上下に何度でも分割でき、
/// ドラッグで自由に移動・入れ替え、境界線でリサイズできるレイアウト。
class TilingLayout extends ConsumerWidget {
  const TilingLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(homeLayoutProvider);

    return layoutAsync.when(
      data: (root) {
        if (root == null) {
          return const _EmptyHome();
        }
        return Padding(
          padding: const EdgeInsets.all(10),
          child: _renderNode(root),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }
}

Widget _renderNode(LayoutNode node) {
  if (node is LeafNode) {
    return KeyedSubtree(
      key: ValueKey('leaf-${node.widgetType}'),
      child: _LeafTile(widgetType: node.widgetType),
    );
  }
  final split = node as SplitNode;
  return KeyedSubtree(
    key: ValueKey('split-${split.id}'),
    child: _SplitView(node: split, first: _renderNode(split.first), second: _renderNode(split.second)),
  );
}

class _EmptyHome extends ConsumerWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dashboard_customize_outlined,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('ホーム画面には何も配置されていません'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final chosen = await showWidgetPicker(context, allWidgetTypes);
              if (chosen != null) {
                ref.read(homeLayoutProvider.notifier).addWidget(chosen);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('ウィジェットを追加'),
          ),
        ],
      ),
    );
  }
}

class _SplitView extends ConsumerWidget {
  const _SplitView({required this.node, required this.first, required this.second});

  final SplitNode node;
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHorizontal = node.axis == Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalExtent = isHorizontal ? constraints.maxWidth : constraints.maxHeight;

        void onDragUpdate(DragUpdateDetails details) {
          if (totalExtent <= 0) return;
          final delta = isHorizontal ? details.delta.dx : details.delta.dy;
          final newRatio = (node.ratio + delta / totalExtent).clamp(0.15, 0.85);
          ref.read(homeLayoutProvider.notifier).updateRatio(node.id, newRatio);
        }

        final children = <Widget>[
          Expanded(flex: (node.ratio * 1000).round().clamp(1, 999), child: first),
          _SplitDivider(isHorizontal: isHorizontal, onDragUpdate: onDragUpdate),
          Expanded(flex: ((1 - node.ratio) * 1000).round().clamp(1, 999), child: second),
        ];

        return isHorizontal
            ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
      },
    );
  }
}

class _SplitDivider extends StatelessWidget {
  const _SplitDivider({required this.isHorizontal, required this.onDragUpdate});

  final bool isHorizontal;
  final void Function(DragUpdateDetails) onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: isHorizontal ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: isHorizontal ? onDragUpdate : null,
        onVerticalDragUpdate: isHorizontal ? null : onDragUpdate,
        child: SizedBox(
          width: isHorizontal ? 14 : double.infinity,
          height: isHorizontal ? double.infinity : 14,
          child: Center(
            child: Container(
              width: isHorizontal ? 3 : 28,
              height: isHorizontal ? 28 : 3,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeafTile extends ConsumerStatefulWidget {
  const _LeafTile({required this.widgetType});

  final String widgetType;

  @override
  ConsumerState<_LeafTile> createState() => _LeafTileState();
}

class _LeafTileState extends ConsumerState<_LeafTile> {
  _DropZone? _hoverZone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final route = routeFor(widget.widgetType);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != widget.widgetType,
      onMove: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final local = box.globalToLocal(details.offset);
        final zone = _zoneFor(local, box.size);
        if (zone != _hoverZone) setState(() => _hoverZone = zone);
      },
      onLeave: (_) => setState(() => _hoverZone = null),
      onAcceptWithDetails: (details) {
        final zone = _hoverZone ?? _DropZone.center;
        setState(() => _hoverZone = null);
        final notifier = ref.read(homeLayoutProvider.notifier);
        switch (zone) {
          case _DropZone.center:
            notifier.swapWidgets(details.data, widget.widgetType);
            break;
          case _DropZone.left:
            notifier.moveWidgetToEdge(details.data, widget.widgetType, Axis.horizontal,
                draggedIsSecond: false);
            break;
          case _DropZone.right:
            notifier.moveWidgetToEdge(details.data, widget.widgetType, Axis.horizontal,
                draggedIsSecond: true);
            break;
          case _DropZone.top:
            notifier.moveWidgetToEdge(details.data, widget.widgetType, Axis.vertical,
                draggedIsSecond: false);
            break;
          case _DropZone.bottom:
            notifier.moveWidgetToEdge(details.data, widget.widgetType, Axis.vertical,
                draggedIsSecond: true);
            break;
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            PaneTile(
              widgetType: widget.widgetType,
              onExpand: route != null ? () => context.go(route) : null,
              trailing: [
                _SplitMenuButton(widgetType: widget.widgetType),
                Draggable<String>(
                  data: widget.widgetType,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 260,
                      height: 160,
                      child: Opacity(
                        opacity: 0.85,
                        child: PaneTile(widgetType: widget.widgetType),
                      ),
                    ),
                  ),
                  childWhenDragging: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.drag_indicator_rounded, size: 18, color: scheme.outline),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.drag_indicator_rounded, size: 18),
                  ),
                ),
              ],
            ),
            if (candidateData.isNotEmpty && _hoverZone != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: _ZoneHighlight(zone: _hoverZone!, color: scheme.primary),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ZoneHighlight extends StatelessWidget {
  const _ZoneHighlight({required this.zone, required this.color});

  final _DropZone zone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Alignment align;
    var widthFactor = 1.0;
    var heightFactor = 1.0;
    switch (zone) {
      case _DropZone.left:
        align = Alignment.centerLeft;
        widthFactor = 0.35;
        break;
      case _DropZone.right:
        align = Alignment.centerRight;
        widthFactor = 0.35;
        break;
      case _DropZone.top:
        align = Alignment.topCenter;
        heightFactor = 0.35;
        break;
      case _DropZone.bottom:
        align = Alignment.bottomCenter;
        heightFactor = 0.35;
        break;
      case _DropZone.center:
        align = Alignment.center;
        widthFactor = 0.6;
        heightFactor = 0.6;
        break;
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Align(
        alignment: align,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          heightFactor: heightFactor,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitMenuButton extends ConsumerWidget {
  const _SplitMenuButton({required this.widgetType});

  final String widgetType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 18),
      tooltip: 'この項目の操作',
      onSelected: (action) async {
        final notifier = ref.read(homeLayoutProvider.notifier);
        if (action == 'remove') {
          notifier.removeWidget(widgetType);
          return;
        }
        final axis = action == 'split_right' ? Axis.horizontal : Axis.vertical;
        final currentTypes = allTypesIn(ref.read(homeLayoutProvider).value);
        final available = allWidgetTypes.where((t) => !currentTypes.contains(t)).toList();
        if (!context.mounted) return;
        final chosen = await showWidgetPicker(context, available);
        if (chosen != null) {
          notifier.splitWithNewWidget(widgetType, axis, chosen, newIsSecond: true);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'split_right', child: Text('右に分割')),
        const PopupMenuItem(value: 'split_down', child: Text('下に分割')),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'remove',
          child: Text('「${paneStyles[widgetType]!.label}」を削除'),
        ),
      ],
    );
  }
}
