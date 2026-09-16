import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart' show Axis;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kHomeLayoutKey = 'home_layout_tree_v3';
final _idRandom = Random();

String _newSplitId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${_idRandom.nextInt(1 << 32)}';

/// ホーム画面のレイアウトを表す2分木。
/// [LeafNode] が1つのウィジェット、[SplitNode] が左右/上下の分割を表す。
sealed class LayoutNode {
  const LayoutNode();
}

class LeafNode extends LayoutNode {
  const LeafNode(this.widgetType);
  final String widgetType;
}

class SplitNode extends LayoutNode {
  const SplitNode({
    required this.id,
    required this.axis,
    required this.ratio,
    required this.first,
    required this.second,
  });

  /// Axis.horizontal = 左右分割、Axis.vertical = 上下分割
  final String id;
  final Axis axis;
  final double ratio;
  final LayoutNode first;
  final LayoutNode second;
}

LayoutNode get _defaultLayout => SplitNode(
      id: 'root',
      axis: Axis.vertical,
      ratio: 0.62,
      first: SplitNode(
        id: _newSplitId(),
        axis: Axis.horizontal,
        ratio: 0.5,
        first: const LeafNode('tasks'),
        second: const LeafNode('schedules'),
      ),
      second: const LeafNode('memos'),
    );

// ---- ツリー操作（すべて純粋関数。新しいツリーを返す） ----

Set<String> allTypesIn(LayoutNode? node) {
  if (node == null) return {};
  if (node is LeafNode) return {node.widgetType};
  final s = node as SplitNode;
  return {...allTypesIn(s.first), ...allTypesIn(s.second)};
}

List<String> flattenLeaves(LayoutNode? node) {
  if (node == null) return [];
  if (node is LeafNode) return [node.widgetType];
  final s = node as SplitNode;
  return [...flattenLeaves(s.first), ...flattenLeaves(s.second)];
}

bool containsType(LayoutNode node, String type) => allTypesIn(node).contains(type);

LayoutNode? _removeType(LayoutNode node, String type) {
  if (node is LeafNode) {
    return node.widgetType == type ? null : node;
  }
  final s = node as SplitNode;
  if (s.first is LeafNode && (s.first as LeafNode).widgetType == type) return s.second;
  if (s.second is LeafNode && (s.second as LeafNode).widgetType == type) return s.first;
  return SplitNode(
    id: s.id,
    axis: s.axis,
    ratio: s.ratio,
    first: _removeType(s.first, type) ?? s.first,
    second: _removeType(s.second, type) ?? s.second,
  );
}

LayoutNode _splitWithType(
  LayoutNode node,
  String targetType,
  Axis axis,
  String newType, {
  required bool newIsSecond,
}) {
  if (node is LeafNode) {
    if (node.widgetType != targetType) return node;
    final newLeaf = LeafNode(newType);
    return SplitNode(
      id: _newSplitId(),
      axis: axis,
      ratio: 0.5,
      first: newIsSecond ? node : newLeaf,
      second: newIsSecond ? newLeaf : node,
    );
  }
  final s = node as SplitNode;
  return SplitNode(
    id: s.id,
    axis: s.axis,
    ratio: s.ratio,
    first: _splitWithType(s.first, targetType, axis, newType, newIsSecond: newIsSecond),
    second: _splitWithType(s.second, targetType, axis, newType, newIsSecond: newIsSecond),
  );
}

LayoutNode _swapTypes(LayoutNode node, String typeA, String typeB) {
  if (node is LeafNode) {
    if (node.widgetType == typeA) return LeafNode(typeB);
    if (node.widgetType == typeB) return LeafNode(typeA);
    return node;
  }
  final s = node as SplitNode;
  return SplitNode(
    id: s.id,
    axis: s.axis,
    ratio: s.ratio,
    first: _swapTypes(s.first, typeA, typeB),
    second: _swapTypes(s.second, typeA, typeB),
  );
}

LayoutNode _updateRatio(LayoutNode node, String splitId, double ratio) {
  if (node is LeafNode) return node;
  final s = node as SplitNode;
  if (s.id == splitId) {
    return SplitNode(id: s.id, axis: s.axis, ratio: ratio, first: s.first, second: s.second);
  }
  return SplitNode(
    id: s.id,
    axis: s.axis,
    ratio: s.ratio,
    first: _updateRatio(s.first, splitId, ratio),
    second: _updateRatio(s.second, splitId, ratio),
  );
}

// ---- JSON 変換 ----

Map<String, dynamic> _nodeToJson(LayoutNode node) {
  if (node is LeafNode) {
    return {'t': 'leaf', 'widgetType': node.widgetType};
  }
  final s = node as SplitNode;
  return {
    't': 'split',
    'id': s.id,
    'axis': s.axis == Axis.horizontal ? 'h' : 'v',
    'ratio': s.ratio,
    'first': _nodeToJson(s.first),
    'second': _nodeToJson(s.second),
  };
}

LayoutNode _nodeFromJson(Map<String, dynamic> json) {
  if (json['t'] == 'leaf') {
    return LeafNode(json['widgetType'] as String);
  }
  return SplitNode(
    id: json['id'] as String,
    axis: json['axis'] == 'h' ? Axis.horizontal : Axis.vertical,
    ratio: (json['ratio'] as num).toDouble(),
    first: _nodeFromJson(json['first'] as Map<String, dynamic>),
    second: _nodeFromJson(json['second'] as Map<String, dynamic>),
  );
}

/// ホーム画面のレイアウト（2分木）。追加・削除・分割・リサイズ・入れ替えの
/// すべての操作結果を SharedPreferences に永続化する。null = 何も配置されていない状態。
class HomeLayoutNotifier extends AsyncNotifier<LayoutNode?> {
  @override
  Future<LayoutNode?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kHomeLayoutKey);
    if (stored == null) return _defaultLayout;
    try {
      return _nodeFromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (_) {
      return _defaultLayout;
    }
  }

  Future<void> _persist(LayoutNode? node) async {
    state = AsyncData(node);
    final prefs = await SharedPreferences.getInstance();
    if (node == null) {
      await prefs.remove(_kHomeLayoutKey);
    } else {
      await prefs.setString(_kHomeLayoutKey, jsonEncode(_nodeToJson(node)));
    }
  }

  /// 新しいウィジェットを、既存レイアウト全体の下に追加する。
  Future<void> addWidget(String widgetType) async {
    final current = state.value;
    if (current != null && containsType(current, widgetType)) return;
    if (current == null) {
      await _persist(LeafNode(widgetType));
      return;
    }
    await _persist(SplitNode(
      id: _newSplitId(),
      axis: Axis.vertical,
      ratio: 0.66,
      first: current,
      second: LeafNode(widgetType),
    ));
  }

  /// [targetType] の位置を分割し、新しいウィジェットを追加する。
  Future<void> splitWithNewWidget(
    String targetType,
    Axis axis,
    String newWidgetType, {
    required bool newIsSecond,
  }) async {
    final current = state.value;
    if (current == null) return;
    if (containsType(current, newWidgetType)) return;
    await _persist(_splitWithType(current, targetType, axis, newWidgetType, newIsSecond: newIsSecond));
  }

  /// 既存の [draggedType] を取り除き、[targetType] の位置を分割してそこへ移動する。
  Future<void> moveWidgetToEdge(
    String draggedType,
    String targetType,
    Axis axis, {
    required bool draggedIsSecond,
  }) async {
    final current = state.value;
    if (current == null || draggedType == targetType) return;
    final withoutDragged = _removeType(current, draggedType);
    if (withoutDragged == null) return;
    await _persist(
      _splitWithType(withoutDragged, targetType, axis, draggedType, newIsSecond: draggedIsSecond),
    );
  }

  Future<void> swapWidgets(String typeA, String typeB) async {
    final current = state.value;
    if (current == null || typeA == typeB) return;
    await _persist(_swapTypes(current, typeA, typeB));
  }

  Future<void> removeWidget(String widgetType) async {
    final current = state.value;
    if (current == null) return;
    await _persist(_removeType(current, widgetType));
  }

  Future<void> updateRatio(String splitId, double ratio) async {
    final current = state.value;
    if (current == null) return;
    await _persist(_updateRatio(current, splitId, ratio));
  }

  Future<void> resetLayout() => _persist(_defaultLayout);
}

final homeLayoutProvider =
    AsyncNotifierProvider<HomeLayoutNotifier, LayoutNode?>(HomeLayoutNotifier.new);
