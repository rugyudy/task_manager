import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kQuickMemoKey = 'quick_memo_text';

/// タイトル不要ですぐ書ける付箋的なメモ（既存の「メモ」機能とは別の1本だけの走り書き）。
class QuickMemoNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kQuickMemoKey) ?? '';
  }

  Future<void> update(String text) async {
    state = AsyncData(text);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQuickMemoKey, text);
  }
}

final quickMemoProvider = AsyncNotifierProvider<QuickMemoNotifier, String>(QuickMemoNotifier.new);
