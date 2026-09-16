import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/memo.dart';
import '../../providers/memo_provider.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/tag_editor.dart';

class MemosScreen extends ConsumerStatefulWidget {
  const MemosScreen({super.key});

  @override
  ConsumerState<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends ConsumerState<MemosScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Memo> _filter(List<Memo> memos) {
    final query = _searchController.text.trim().toLowerCase();
    return memos.where((memo) {
      if (query.isNotEmpty &&
          !memo.title.toLowerCase().contains(query) &&
          !memo.content.toLowerCase().contains(query)) {
        return false;
      }
      if (_selectedTags.isNotEmpty && !_selectedTags.every(memo.tags.contains)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _showMemoDialog({Memo? memo}) {
    final titleController = TextEditingController(text: memo?.title ?? '');
    final contentController = TextEditingController(text: memo?.content ?? '');
    var tags = List<String>.from(memo?.tags ?? const []);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(memo == null ? '新しいメモ' : 'メモを編集'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 12),
                      TagEditor(
                        tags: tags,
                        onChanged: (updated) => setState(() => tags = updated),
                      ),
                    ],
                  ),
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
                        tags: tags,
                      );
                    } else {
                      memo
                        ..title = title
                        ..content = contentController.text
                        ..tags = tags;
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final memosAsync = ref.watch(memosStreamProvider);

    return Scaffold(
      body: memosAsync.when(
        data: (allMemos) {
          final allTags = allMemos.expand((m) => m.tags).toSet().toList()..sort();
          final memos = _filter(allMemos);

          return Column(
            children: [
              SearchFilterBar(
                searchController: _searchController,
                allTags: allTags,
                selectedTags: _selectedTags,
                onTagToggled: (tag) => setState(() {
                  if (!_selectedTags.remove(tag)) _selectedTags.add(tag);
                }),
              ),
              Expanded(
                child: memos.isEmpty
                    ? const Center(child: Text('該当するメモがありません'))
                    : ListView.builder(
                        itemCount: memos.length,
                        itemBuilder: (context, index) {
                          final memo = memos[index];
                          return ListTile(
                            leading: const Icon(Icons.note_outlined),
                            title: Text(memo.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  memo.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (memo.tags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 4,
                                      children: [
                                        for (final tag in memo.tags)
                                          Chip(
                                            label: Text(tag, style: const TextStyle(fontSize: 11)),
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _showMemoDialog(memo: memo),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  ref.read(memoControllerProvider).deleteMemo(memo.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMemoDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
