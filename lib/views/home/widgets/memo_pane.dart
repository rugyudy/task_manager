import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/memo_provider.dart';

class MemoPane extends ConsumerWidget {
  const MemoPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memosStreamProvider);

    return memosAsync.when(
      data: (memos) {
        if (memos.isEmpty) {
          return const Center(child: Text('メモはありません'));
        }
        final visible = memos.take(20).toList();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final memo = visible[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.sticky_note_2_rounded, size: 20),
              title: Text(memo.title),
              subtitle: Text(
                memo.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
