import 'package:flutter/material.dart';

import '../../../core/widget_catalog.dart';
import 'pane_card.dart';

/// カタログ上のウィジェット種別を、共通の PaneCard（ヘッダー付きカード）で包む。
class PaneTile extends StatelessWidget {
  const PaneTile({
    super.key,
    required this.widgetType,
    this.onExpand,
    this.trailing = const [],
  });

  final String widgetType;
  final VoidCallback? onExpand;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return PaneCard(
      paneKey: widgetType,
      onExpand: onExpand,
      trailing: trailing,
      child: buildPaneContent(widgetType),
    );
  }
}
