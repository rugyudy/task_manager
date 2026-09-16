import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMobileOrderKey = 'home_pane_order';
const _kGridLayoutKey = 'home_grid_layout_v2';

/// ホーム画面に表示するペインの識別子。
const paneKeys = <String>['tasks', 'schedules', 'memos'];

/// PC/タブレット向けダッシュボードの列数（グリッドの吸着単位）。
const gridColumns = 4;

/// グリッド上でのペインの位置・サイズ（列・行はグリッド単位）。
class PaneRect {
  const PaneRect({
    required this.col,
    required this.row,
    this.colSpan = 2,
    this.rowSpan = 1,
  });

  final int col;
  final int row;
  final int colSpan;
  final int rowSpan;

  PaneRect copyWith({int? col, int? row, int? colSpan, int? rowSpan}) {
    return PaneRect(
      col: col ?? this.col,
      row: row ?? this.row,
      colSpan: colSpan ?? this.colSpan,
      rowSpan: rowSpan ?? this.rowSpan,
    );
  }

  Map<String, dynamic> toJson() => {
        'col': col,
        'row': row,
        'colSpan': colSpan,
        'rowSpan': rowSpan,
      };

  factory PaneRect.fromJson(Map<String, dynamic> json) => PaneRect(
        col: json['col'] as int,
        row: json['row'] as int,
        colSpan: json['colSpan'] as int,
        rowSpan: json['rowSpan'] as int,
      );
}

Map<String, PaneRect> get _defaultGridLayout => {
      'tasks': const PaneRect(col: 0, row: 0, colSpan: 2, rowSpan: 1),
      'schedules': const PaneRect(col: 2, row: 0, colSpan: 2, rowSpan: 1),
      'memos': const PaneRect(col: 0, row: 1, colSpan: 4, rowSpan: 1),
    };

/// PC/タブレット向け: 各ペインのグリッド上の位置・サイズ。
/// ドラッグ＆リサイズの結果を SharedPreferences に永続化する。
class GridLayoutNotifier extends AsyncNotifier<Map<String, PaneRect>> {
  @override
  Future<Map<String, PaneRect>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kGridLayoutKey);
    if (stored == null) return _defaultGridLayout;

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      final result = <String, PaneRect>{};
      for (final key in paneKeys) {
        final raw = decoded[key];
        if (raw == null) return _defaultGridLayout;
        result[key] = PaneRect.fromJson(raw as Map<String, dynamic>);
      }
      return result;
    } catch (_) {
      return _defaultGridLayout;
    }
  }

  Future<void> updateLayout(Map<String, PaneRect> layout) async {
    state = AsyncData(layout);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kGridLayoutKey,
      jsonEncode({for (final e in layout.entries) e.key: e.value.toJson()}),
    );
  }
}

final gridLayoutProvider =
    AsyncNotifierProvider<GridLayoutNotifier, Map<String, PaneRect>>(
  GridLayoutNotifier.new,
);

/// スマホ向け: 縦積みのペインの並び順（ドラッグ＆ドロップで並び替え）。
const defaultPaneOrder = paneKeys;

class LayoutOrderNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_kMobileOrderKey);
    if (stored != null &&
        stored.length == defaultPaneOrder.length &&
        stored.toSet().containsAll(defaultPaneOrder)) {
      return stored;
    }
    return List.of(defaultPaneOrder);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.value ?? List.of(defaultPaneOrder);
    final updated = List<String>.from(current);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    state = AsyncData(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kMobileOrderKey, updated);
  }
}

final layoutOrderProvider =
    AsyncNotifierProvider<LayoutOrderNotifier, List<String>>(
  LayoutOrderNotifier.new,
);
