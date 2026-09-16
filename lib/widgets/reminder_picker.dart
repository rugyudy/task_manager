import 'package:flutter/material.dart';

/// key: 期限/開始時刻の何分前に通知するか（null = 通知しない）
const reminderOptions = <int?, String>{
  null: '通知しない',
  0: '時刻ちょうど',
  10: '10分前',
  60: '1時間前',
  1440: '1日前',
};

class ReminderPicker extends StatelessWidget {
  const ReminderPicker({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      value: reminderOptions.containsKey(value) ? value : null,
      decoration: const InputDecoration(labelText: '通知', isDense: true),
      items: [
        for (final entry in reminderOptions.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: onChanged,
    );
  }
}
