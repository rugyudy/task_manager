import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _showScheduleDialog({Schedule? schedule}) {
    final titleController = TextEditingController(text: schedule?.title ?? '');
    var start = schedule?.startTime ?? _selectedDay ?? DateTime.now();
    var end = schedule?.endTime ?? start.add(const Duration(hours: 1));

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> pickDateTime(bool isStart) async {
              final date = await showDatePicker(
                context: dialogContext,
                initialDate: isStart ? start : end,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date == null) return;
              if (!dialogContext.mounted) return;
              final time = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.fromDateTime(isStart ? start : end),
              );
              if (time == null) return;
              final combined = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
              setState(() {
                if (isStart) {
                  start = combined;
                } else {
                  end = combined;
                }
              });
            }

            return AlertDialog(
              title: Text(schedule == null ? '新しい予定' : '予定を編集'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('開始: ${start.toString().split('.').first}'),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () => pickDateTime(true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('終了: ${end.toString().split('.').first}'),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () => pickDateTime(false),
                  ),
                ],
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
                    final controller = ref.read(scheduleControllerProvider);
                    if (schedule == null) {
                      controller.addSchedule(title: title, start: start, end: end);
                    } else {
                      schedule
                        ..title = title
                        ..startTime = start
                        ..endTime = end;
                      controller.updateSchedule(schedule);
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
    final schedulesAsync = ref.watch(schedulesStreamProvider);

    return Scaffold(
      body: schedulesAsync.when(
        data: (schedules) {
          final selected = _selectedDay ?? DateTime.now();
          final eventsByDay = <DateTime, List<Schedule>>{};
          for (final s in schedules) {
            final day = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
            eventsByDay.putIfAbsent(day, () => []).add(s);
          }
          final dayEvents = schedules
              .where((s) => _isSameDay(s.startTime, selected))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          return Column(
            children: [
              TableCalendar<Schedule>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    _selectedDay != null && _isSameDay(_selectedDay!, day),
                eventLoader: (day) =>
                    eventsByDay[DateTime(day.year, day.month, day.day)] ?? [],
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: dayEvents.isEmpty
                    ? const Center(child: Text('この日の予定はありません'))
                    : ListView.builder(
                        itemCount: dayEvents.length,
                        itemBuilder: (context, index) {
                          final s = dayEvents[index];
                          return ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(s.title),
                            subtitle: Text(
                              '${TimeOfDay.fromDateTime(s.startTime).format(context)} - '
                              '${TimeOfDay.fromDateTime(s.endTime).format(context)}',
                            ),
                            onTap: () => _showScheduleDialog(schedule: s),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => ref
                                  .read(scheduleControllerProvider)
                                  .deleteSchedule(s.id),
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
        onPressed: () => _showScheduleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
