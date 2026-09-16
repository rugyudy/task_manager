import 'package:flutter/material.dart';

import '../core/pane_style.dart';

/// タグの追加・削除を行う共通ウィジェット（タスク/スケジュール/メモの編集ダイアログで使用）。
class TagEditor extends StatefulWidget {
  const TagEditor({super.key, required this.tags, required this.onChanged});

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final _controller = TextEditingController();

  void _addTag(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty || widget.tags.contains(tag)) {
      _controller.clear();
      return;
    }
    widget.onChanged([...widget.tags, tag]);
    _controller.clear();
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in widget.tags)
                Chip(
                  label: Text(tag),
                  backgroundColor: colorForTag(tag, scheme).withOpacity(0.14),
                  labelStyle: TextStyle(color: colorForTag(tag, scheme)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => _removeTag(tag),
                ),
            ],
          ),
        if (widget.tags.isNotEmpty) const SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'タグを追加（Enterで確定）',
            isDense: true,
          ),
          onSubmitted: _addTag,
        ),
      ],
    );
  }
}
