import 'package:flutter/material.dart';

/// ホーム画面上の各ペイン（タスク/スケジュール/メモ）の共通の見た目。
class PaneCard extends StatelessWidget {
  const PaneCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onExpand,
    this.dragHandle,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onExpand;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (dragHandle != null) ...[dragHandle!, const SizedBox(width: 8)],
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onExpand != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_full, size: 18),
                    tooltip: '全画面表示',
                    onPressed: onExpand,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
