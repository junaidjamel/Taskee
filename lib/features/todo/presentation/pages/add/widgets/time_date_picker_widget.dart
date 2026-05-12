import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_colors.dart';

class DueAtPicker extends StatelessWidget {
  const DueAtPicker({super.key, required this.dueAt, required this.onChanged});

  final DateTime? dueAt;
  final ValueChanged<DateTime?> onChanged;
  String _weekday(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = dueAt == null
        ? 'Select date'
        : '${_weekday(dueAt!.weekday)}, ${dueAt!.day}, ${dueAt!.year}';

    final timeLabel = dueAt == null
        ? 'Select time'
        : localizations.formatTimeOfDay(
            TimeOfDay.fromDateTime(dueAt!),
            alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
          );

    return Row(
      children: [
        Expanded(
          child: _PickerCard(
            key: const Key('addTodo_dueDate_button'),
            icon: CupertinoIcons.calendar,
            label: 'Date',
            value: dateLabel,
            isPlaceholder: dueAt == null,
            onTap: () async {
              final now = DateTime.now();
              final initial = dueAt ?? now;
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(initial.year, initial.month, initial.day),
                firstDate: DateTime(now.year - 10),
                lastDate: DateTime(now.year + 20),
              );
              if (picked == null) return;
              final currentTime = dueAt == null
                  ? const TimeOfDay(hour: 9, minute: 0)
                  : TimeOfDay.fromDateTime(dueAt!);
              onChanged(
                DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  currentTime.hour,
                  currentTime.minute,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PickerCard(
            key: const Key('addTodo_dueTime_button'),
            icon: CupertinoIcons.clock,
            label: 'Time',
            value: timeLabel,
            isPlaceholder: dueAt == null,
            onTap: () async {
              final initial = dueAt == null
                  ? const TimeOfDay(hour: 9, minute: 0)
                  : TimeOfDay.fromDateTime(dueAt!);
              final picked = await showTimePicker(
                context: context,
                initialTime: initial,
              );
              if (picked == null) return;
              final base = dueAt ?? DateTime.now();
              onChanged(
                DateTime(
                  base.year,
                  base.month,
                  base.day,
                  picked.hour,
                  picked.minute,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;

  static final _accent = AppColors.accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.kGreyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.kBlack, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.kWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isPlaceholder ? AppColors.kgrey : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
