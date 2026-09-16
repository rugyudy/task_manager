import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/reminder_picker.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/tag_editor.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Schedule> _filter(List<Schedule> schedules) {
    final query = _searchController.text.trim().toLowerCase();
    return schedules.where((s) {
      if (query.isNotEmpty && !s.title.toLowerCase().contains(query)) return false;
      if (_selectedTags.isNotEmpty && !_selectedTags.every(s.tags.contains)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _showScheduleDialog({Schedule? schedule}) {
    final titleController = TextEditingController(text: schedule?.title ?? '');
    var start = schedule?.startTime ?? _selectedDay ?? DateTime.now();
    var end = schedule?.endTime ?? start.add(const Duration(hours: 1));
    var tags = List<String>.from(schedule?.tags ?? const []);
    var reminderMinutesBefore = schedule?.reminderMinutesBefore;

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
              content: SingleChildScrollView(
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
                    const SizedBox(height: 4),
                    ReminderPicker(
                      value: reminderMinutesBefore,
                      onChanged: (value) => setState(() => reminderMinutesBefore = value),
                    ),
                    const SizedBox(height: 12),
                    TagEditor(
                      tags: tags,
                      onChanged: (updated) => setState(() => tags = updated),
                    ),
                  ],
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
                    final controller = ref.read(scheduleControllerProvider);
                    if (schedule == null) {
                      controller.addSchedule(
                        title: title,
                        start: start,
                        end: end,
                        tags: tags,
                        reminderMinutesBefore: reminderMinutesBefore,
                      );
                    } else {
                      schedule
                        ..title = title
                        ..startTime = start
                        ..endTime = end
                        ..tags = tags
                        ..reminderMinutesBefore = reminderMinutesBefore;
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
        data: (allSchedules) {
          final allTags = allSchedules.expand((s) => s.tags).toSet().toList()..sort();
          final schedules = _filter(allSchedules);
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
              SearchFilterBar(
                searchController: _searchController,
                allTags: allTags,
                selectedTags: _selectedTags,
                onTagToggled: (tag) => setState(() {
                  if (!_selectedTags.remove(tag)) _selectedTags.add(tag);
                }),
              ),
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${TimeOfDay.fromDateTime(s.startTime).format(context)} - '
                                  '${TimeOfDay.fromDateTime(s.endTime).format(context)}',
                                ),
                                if (s.tags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 4,
                                      children: [
                                        for (final tag in s.tags)
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
