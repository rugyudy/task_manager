import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPaneOrderKey = 'home_pane_order';
const _kPaneWeightsKey = 'home_pane_weights';

/// ホーム画面に表示するペインの識別子と初期表示順。
const defaultPaneOrder = <String>['tasks', 'schedules', 'memos'];

/// ペインの並び順（縦積み/ドラッグ＆ドロップの並び替え結果）を管理する。
/// アプリを再起動しても順序が復元されるよう SharedPreferences に保存する。
class LayoutOrderNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_kPaneOrderKey);
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
    await prefs.setStringList(_kPaneOrderKey, updated);
  }
}

final layoutOrderProvider =
    AsyncNotifierProvider<LayoutOrderNotifier, List<String>>(
  LayoutOrderNotifier.new,
);

/// 分割表示（PC/タブレット）時の各ペインのサイズ比率。
class LayoutWeightsNotifier extends AsyncNotifier<List<double>> {
  @override
  Future<List<double>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPaneWeightsKey);
    if (stored != null) {
      final decoded = (jsonDecode(stored) as List).cast<num>();
      if (decoded.length == defaultPaneOrder.length) {
        return decoded.map((e) => e.toDouble()).toList();
      }
    }
    return List.filled(defaultPaneOrder.length, 1 / defaultPaneOrder.length);
  }

  Future<void> updateWeights(List<double> weights) async {
    state = AsyncData(weights);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPaneWeightsKey, jsonEncode(weights));
  }
}

final layoutWeightsProvider =
    AsyncNotifierProvider<LayoutWeightsNotifier, List<double>>(
  LayoutWeightsNotifier.new,
);
