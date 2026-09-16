import 'package:flutter/material.dart';

import '../../../core/pane_style.dart';

/// ホーム画面上の各ペイン（タスク/スケジュール/メモ）の共通の見た目。
/// モダン＆ミニマルなテイスト: 余白多め・角丸・控えめな影。
class PaneCard extends StatelessWidget {
  const PaneCard({
    super.key,
    required this.paneKey,
    required this.child,
    this.onExpand,
    this.trailing = const [],
  });

  final String paneKey;
  final Widget child;
  final VoidCallback? onExpand;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final style = paneStyles[paneKey]!;
    final scheme = Theme.of(context).colorScheme;
    final accent = style.colorOf(scheme);

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(style.icon, size: 18, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    style.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (onExpand != null)
                  IconButton(
                    icon: const Icon(Icons.north_east_rounded, size: 18),
                    tooltip: '全画面表示',
                    onPressed: onExpand,
                  ),
                ...trailing,
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.35)),
          Expanded(child: child),
        ],
      ),
    );
  }
}
