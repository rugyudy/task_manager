import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/layout_provider.dart';
import 'memo_pane.dart';
import 'pane_card.dart';
import 'schedule_pane.dart';
import 'task_pane.dart';

const _rowHeight = 280.0;
const _gap = 12.0;
const _minColSpan = 1;
const _minRowSpan = 1;
const _maxRowSpan = 3;

Widget _paneContentFor(String key) {
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

/// PC/タブレット向け: 見えないグリッドに吸着しながら自由に配置・リサイズできるダッシュボード。
class DashboardGrid extends ConsumerStatefulWidget {
  const DashboardGrid({super.key});

  @override
  ConsumerState<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends ConsumerState<DashboardGrid> {
  String? _draggingKey;
  PaneRect? _previewRect;
  final GlobalKey _gridKey = GlobalKey();

  int _rowCountOf(Map<String, PaneRect> layout) {
    var maxRow = 1;
    for (final rect in layout.values) {
      final bottom = rect.row + rect.rowSpan;
      if (bottom > maxRow) maxRow = bottom;
    }
    return maxRow;
  }

  bool _overlaps(PaneRect a, PaneRect b) {
    final aRight = a.col + a.colSpan;
    final bRight = b.col + b.colSpan;
    final aBottom = a.row + a.rowSpan;
    final bBottom = b.row + b.rowSpan;
    return a.col < bRight && aRight > b.col && a.row < bBottom && aBottom > b.row;
  }

  PaneRect _clampRect(PaneRect rect, int rowCount) {
    final colSpan = rect.colSpan.clamp(_minColSpan, gridColumns);
    final col = rect.col.clamp(0, gridColumns - colSpan);
    final rowSpan = rect.rowSpan.clamp(_minRowSpan, _maxRowSpan);
    final maxRow = (rowCount - rowSpan) < 0 ? 0 : rowCount - rowSpan;
    final row = rect.row.clamp(0, maxRow);
    return PaneRect(col: col, row: row, colSpan: colSpan, rowSpan: rowSpan);
  }

  void _moveTo(Map<String, PaneRect> layout, String key, int col, int row) {
    final current = layout[key]!;
    final rowCount = _rowCountOf(layout) + 1;
    final target = _clampRect(
      PaneRect(col: col, row: row, colSpan: current.colSpan, rowSpan: current.rowSpan),
      rowCount,
    );
    if (target.col == current.col && target.row == current.row) return;

    final updated = Map<String, PaneRect>.from(layout);
    final occupantKey = updated.entries
        .firstWhere(
          (e) => e.key != key && _overlaps(e.value, target),
          orElse: () => const MapEntry('', PaneRect(col: -1, row: -1)),
        )
        .key;
    if (occupantKey.isNotEmpty) {
      updated[occupantKey] = current;
    }
    updated[key] = target;
    ref.read(gridLayoutProvider.notifier).updateLayout(updated);
  }

  void _resize(Map<String, PaneRect> layout, String key, int colSpanDelta, int rowSpanDelta) {
    final current = layout[key]!;
    final rowCount = _rowCountOf(layout) + _maxRowSpan;
    final target = _clampRect(
      current.copyWith(
        colSpan: current.colSpan + colSpanDelta,
        rowSpan: current.rowSpan + rowSpanDelta,
      ),
      rowCount,
    );
    if (target.colSpan == current.colSpan && target.rowSpan == current.rowSpan) return;
    final updated = Map<String, PaneRect>.from(layout)..[key] = target;
    ref.read(gridLayoutProvider.notifier).updateLayout(updated);
  }

  Offset? _localPointFromGlobal(Offset global) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(gridLayoutProvider);

    return layoutAsync.when(
      data: (layout) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth =
                (constraints.maxWidth - _gap * (gridColumns - 1)) / gridColumns;
            final rowCount = _rowCountOf(layout);
            final totalHeight = rowCount * _rowHeight + (rowCount - 1) * _gap;
            final cellStepX = cellWidth + _gap;
            const cellStepY = _rowHeight + _gap;

            Rect rectFor(PaneRect r) => Rect.fromLTWH(
                  r.col * cellStepX,
                  r.row * cellStepY,
                  r.colSpan * cellWidth + (r.colSpan - 1) * _gap,
                  r.rowSpan * _rowHeight + (r.rowSpan - 1) * _gap,
                );

            void handleMove(String draggedKey, Offset globalOffset) {
              final local = _localPointFromGlobal(globalOffset);
              if (local == null) return;
              final current = layout[draggedKey]!;
              final col = (local.dx / cellStepX).round().clamp(0, gridColumns - current.colSpan);
              final row = (local.dy / cellStepY).round().clamp(0, rowCount);
              setState(() {
                _draggingKey = draggedKey;
                _previewRect = PaneRect(
                  col: col,
                  row: row,
                  colSpan: current.colSpan,
                  rowSpan: current.rowSpan,
                );
              });
            }

            return Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                key: _gridKey,
                height: totalHeight,
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) => true,
                  onMove: (details) => handleMove(details.data, details.offset),
                  onLeave: (_) => setState(() {
                    _draggingKey = null;
                    _previewRect = null;
                  }),
                  onAcceptWithDetails: (details) {
                    final local = _localPointFromGlobal(details.offset);
                    setState(() {
                      _draggingKey = null;
                      _previewRect = null;
                    });
                    if (local == null) return;
                    final current = layout[details.data]!;
                    final col =
                        (local.dx / cellStepX).round().clamp(0, gridColumns - current.colSpan);
                    final row = (local.dy / cellStepY).round().clamp(0, rowCount);
                    _moveTo(layout, details.data, col, row);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (_previewRect != null)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            left: rectFor(_previewRect!).left,
                            top: rectFor(_previewRect!).top,
                            width: rectFor(_previewRect!).width,
                            height: rectFor(_previewRect!).height,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        for (final key in layout.keys)
                          AnimatedPositioned(
                            key: ValueKey(key),
                            duration: Duration(milliseconds: _draggingKey == key ? 0 : 180),
                            curve: Curves.easeOut,
                            left: rectFor(layout[key]!).left,
                            top: rectFor(layout[key]!).top,
                            width: rectFor(layout[key]!).width,
                            height: rectFor(layout[key]!).height,
                            child: Opacity(
                              opacity: _draggingKey == key ? 0.35 : 1,
                              child: _DashboardPaneTile(
                                paneKey: key,
                                cellWidth: cellWidth,
                                onResize: (dCol, dRow) => _resize(layout, key, dCol, dRow),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
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

class _DashboardPaneTile extends StatelessWidget {
  const _DashboardPaneTile({
    required this.paneKey,
    required this.cellWidth,
    required this.onResize,
  });

  final String paneKey;
  final double cellWidth;
  final void Function(int colSpanDelta, int rowSpanDelta) onResize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PaneCard(
          paneKey: paneKey,
          dragHandle: Draggable<String>(
            data: paneKey,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: SizedBox(
              width: 280,
              height: 180,
              child: Opacity(
                opacity: 0.85,
                child: Material(
                  color: Colors.transparent,
                  child: PaneCard(paneKey: paneKey, child: _paneContentFor(paneKey)),
                ),
              ),
            ),
            childWhenDragging: const SizedBox.shrink(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.drag_indicator_rounded, size: 18),
            ),
          ),
          child: _paneContentFor(paneKey),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: _ResizeHandle(cellWidth: cellWidth, onResize: onResize),
        ),
      ],
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({required this.cellWidth, required this.onResize});

  final double cellWidth;
  final void Function(int colSpanDelta, int rowSpanDelta) onResize;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  double _accX = 0;
  double _accY = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        _accX = 0;
        _accY = 0;
      },
      onPanUpdate: (details) {
        _accX += details.delta.dx;
        _accY += details.delta.dy;
        final stepX = widget.cellWidth + _gap;
        const stepY = _rowHeight + _gap;
        var dCol = 0;
        var dRow = 0;
        while (_accX.abs() >= stepX) {
          dCol += _accX > 0 ? 1 : -1;
          _accX += _accX > 0 ? -stepX : stepX;
        }
        while (_accY.abs() >= stepY) {
          dRow += _accY > 0 ? 1 : -1;
          _accY += _accY > 0 ? -stepY : stepY;
        }
        if (dCol != 0 || dRow != 0) {
          widget.onResize(dCol, dRow);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeDownRight,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10)),
          ),
          child: Icon(Icons.south_east_rounded, size: 14, color: scheme.outline),
        ),
      ),
    );
  }
}
