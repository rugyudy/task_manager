import 'package:flutter/material.dart';

/// ホーム画面のペイン（タスク/スケジュール/メモ）ごとの見た目情報。
class PaneStyle {
  const PaneStyle({required this.label, required this.icon, required this.colorOf});

  final String label;
  final IconData icon;
  final Color Function(ColorScheme scheme) colorOf;
}

const paneStyles = <String, PaneStyle>{
  'tasks': PaneStyle(
    label: 'タスク',
    icon: Icons.check_circle_rounded,
    colorOf: _primary,
  ),
  'schedules': PaneStyle(
    label: 'スケジュール',
    icon: Icons.calendar_month_rounded,
    colorOf: _tertiary,
  ),
  'memos': PaneStyle(
    label: 'メモ',
    icon: Icons.sticky_note_2_rounded,
    colorOf: _secondary,
  ),
};

Color _primary(ColorScheme s) => s.primary;
Color _tertiary(ColorScheme s) => s.tertiary;
Color _secondary(ColorScheme s) => s.secondary;

/// タグ文字列から常に同じ色を割り当てる（タグごとの視認性のため）。
Color colorForTag(String tag, ColorScheme scheme) {
  final palette = [
    scheme.primary,
    scheme.secondary,
    scheme.tertiary,
    scheme.error,
  ];
  final index = tag.codeUnits.fold<int>(0, (sum, c) => sum + c) % palette.length;
  return palette[index];
}
