import 'package:flutter/material.dart';

import '../../../core/pane_style.dart';

/// 追加できるウィジェットの一覧をボトムシートで表示し、選ばれた種別キーを返す。
Future<String?> showWidgetPicker(BuildContext context, List<String> availableTypes) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      if (availableTypes.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Text('追加できるウィジェットはすべて配置済みです'),
        );
      }
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final type in availableTypes)
              ListTile(
                leading: Icon(paneStyles[type]!.icon),
                title: Text(paneStyles[type]!.label),
                onTap: () => Navigator.of(context).pop(type),
              ),
          ],
        ),
      );
    },
  );
}
