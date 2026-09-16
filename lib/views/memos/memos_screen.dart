import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/memo.dart';
import '../../providers/memo_provider.dart';

class MemosScreen extends ConsumerWidget {
  const MemosScreen({super.key});

  Future<void> _showMemoDialog(
    BuildContext context,
    WidgetRef ref, {
    Memo? memo,
  }) {
    final titleController = TextEditingController(text: memo?.title ?? '');
    final contentController = TextEditingController(text: memo?.content ?? '');

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(memo == null ? '新しいメモ' : 'メモを編集'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'タイトル'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: '内容'),
                  maxLines: 6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final controller = ref.read(memoControllerProvider);
                if (memo == null) {
                  controller.addMemo(
                    title: title,
                    content: contentController.text,
                  );
                } else {
                  memo
                    ..title = title
                    ..content = contentController.text;
                  controller.updateMemo(memo);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memosStreamProvider);

    return Scaffold(
      body: memosAsync.when(
        data: (memos) {
          if (memos.isEmpty) {
            return const Center(child: Text('メモがありません。右下の + から追加しましょう。'));
          }
          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];
              return ListTile(
                leading: const Icon(Icons.note_outlined),
                title: Text(memo.title),
                subtitle: Text(
                  memo.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _showMemoDialog(context, ref, memo: memo),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      ref.read(memoControllerProvider).deleteMemo(memo.id),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMemoDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
