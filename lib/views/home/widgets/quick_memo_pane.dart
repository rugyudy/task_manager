import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/quick_memo_provider.dart';

/// タイトル不要ですぐ書ける付箋的なメモ。既存の「メモ」機能とは別の走り書き用。
class QuickMemoPane extends ConsumerStatefulWidget {
  const QuickMemoPane({super.key});

  @override
  ConsumerState<QuickMemoPane> createState() => _QuickMemoPaneState();
}

class _QuickMemoPaneState extends ConsumerState<QuickMemoPane> {
  final _controller = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textAsync = ref.watch(quickMemoProvider);

    return textAsync.when(
      data: (text) {
        if (!_loaded) {
          _controller.text = text;
          _loaded = true;
        }
        return Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: '思いついたことをすぐメモ…',
              border: InputBorder.none,
            ),
            onChanged: (value) => ref.read(quickMemoProvider.notifier).update(value),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }
}
