import 'package:flutter/material.dart';

import '../core/pane_style.dart';

/// 各一覧画面共通の検索バー＋タグ絞り込みチップ。
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.allTags,
    required this.selectedTags,
    required this.onTagToggled,
    this.extraFilter,
  });

  final TextEditingController searchController;
  final List<String> allTags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final Widget? extraFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              hintText: '検索',
              isDense: true,
            ),
          ),
          if (allTags.isNotEmpty || extraFilter != null) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (extraFilter != null) ...[extraFilter!, const SizedBox(width: 8)],
                  for (final tag in allTags)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(tag),
                        selected: selectedTags.contains(tag),
                        onSelected: (_) => onTagToggled(tag),
                        selectedColor: colorForTag(tag, scheme).withOpacity(0.18),
                        checkmarkColor: colorForTag(tag, scheme),
                        labelStyle: TextStyle(
                          color: selectedTags.contains(tag)
                              ? colorForTag(tag, scheme)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
